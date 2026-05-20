extends EnemyController

class_name EndlessEnemyController

# Enemy metadata
class EnemyDef:
	var type: EnemyType
	var points: int
	var min_wave: int
	var max_wave: int = 9999
	var delays: Array[float] # Changes every 5 waves

	func _init(t: EnemyType, pts: int, mw: int, dl: Array[float], mxw: int = 9999):
		type = t
		points = pts
		min_wave = mw
		delays = dl
		max_wave = mxw

var _enemy_pool: Array[EnemyDef] = []

# Wave pools from wave 1 to 36 (0-indexed 0 to 35)
var _wave_pools: Array[int] = [
	40, 50, 60, 80, 120, 140, 224, 170, 190, 220,
	380, 300, 375, 450, 504, 616, 700, 650, 1100, 855,
	1000, 1100, 1200, 1300, 1400, 1500, 1500, 1800, 2000, 2640,
	3300, 1000, 1250, 2100, 2660, 6600
]

var _wave_rng := RandomNumberGenerator.new()

func _ready() -> void:
	_wave_rng.randomize()
	_setup_enemy_pool()
	if waveDefs == null:
		waveDefs = Waves.new()
	waveDefs.waves.clear()
	waveDefs.initial_coins = 250
	ensure_wave_exists(0)
	super._ready()


func _setup_enemy_pool() -> void:
	# Płotka
	_enemy_pool.append(EnemyDef.new(
		preload("res://resources/enemy_defs/Plotka.tres"),
		5, 0, [0.3, 0.3, 0.25, 0.2, 0.15, 0.1, 0.1, 0.1], 29
	))
	# Węgorz
	_enemy_pool.append(EnemyDef.new(
		preload("res://resources/enemy_defs/Wegorz.tres"),
		15, 4, [1.0, 0.8, 0.7, 0.6, 0.5, 0.25, 0.2, 0.1]
	))
	# Dorsz
	_enemy_pool.append(EnemyDef.new(
		preload("res://resources/enemy_defs/Dorsz.tres"),
		28, 7, [0.0, 1.5, 0.9, 0.8, 0.7, 0.6, 0.4, 0.3]
	))
	# Łosoś czerwony
	_enemy_pool.append(EnemyDef.new(
		preload("res://resources/enemy_defs/LososCzerwony.tres"),
		35, 10, [0.0, 0.0, 1.2, 1.0, 0.8, 0.6, 0.4, 0.3]
	))
	# Sum
	_enemy_pool.append(EnemyDef.new(
		preload("res://resources/enemy_defs/Sum.tres"),
		95, 11, [0.0, 0.0, 2.0, 1.7, 1.2, 0.9, 0.6, 0.5]
	))
	# Jesiotr Zachodni
	_enemy_pool.append(EnemyDef.new(
		preload("res://resources/enemy_defs/JesiotrZachodni.tres"),
		220, 17, [0.0, 0.0, 0.0, 3.0, 2.5, 1.8, 1.5, 0.9]
	))
	# Halibut pacyficzny
	_enemy_pool.append(EnemyDef.new(
		preload("res://resources/enemy_defs/HalibutPacyficzny.tres"),
		350, 25, [0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 4.0, 3.0]
	))
	# Jesiotr biały
	_enemy_pool.append(EnemyDef.new(
		preload("res://resources/enemy_defs/JesiotrBialy.tres"),
		550, 35, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 8.0]
	))


func is_endless_mode() -> bool:
	return true


func ensure_wave_exists(wave_index: int) -> bool:
	if wave_index < 0:
		return false
	if waveDefs == null:
		waveDefs = Waves.new()
	while waveDefs.waves.size() <= wave_index:
		waveDefs.waves.append(_build_wave(waveDefs.waves.size()))
	return true


func _build_wave(wave_index: int) -> Wave:
	var wave := Wave.new()
	var points_pool = get_points_pool(wave_index)
	
	wave.start_delay = get_start_delay(wave_index)
	
	var chosen_enemies := {} # EnemyDef -> Count
	
	# Available enemies for this wave
	var available: Array[EnemyDef] = []
	var delay_idx = mini(wave_index / 5, 7)
	
	for ed in _enemy_pool:
		if wave_index >= ed.min_wave and wave_index <= ed.max_wave:
			if ed.delays[delay_idx] > 0.0:
				available.append(ed)
	
	var current_points = 0
	while current_points < points_pool and not available.is_empty():
		# Filter available to only those that fit
		var affordable: Array[EnemyDef] = []
		for ed in available:
			if current_points + ed.points <= points_pool:
				affordable.append(ed)
		
		if affordable.is_empty():
			break
			
		var picked = affordable[_wave_rng.randi() % affordable.size()]
		chosen_enemies[picked] = chosen_enemies.get(picked, 0) + 1
		current_points += picked.points

	# Create WaveEntry sorted by enemy index in _enemy_pool (as a proxy for type sorting)
	for i in range(_enemy_pool.size()):
		var ed = _enemy_pool[i]
		if chosen_enemies.has(ed):
			var entry = WaveEntry.new()
			entry.enemy_type = ed.type
			entry.count = chosen_enemies[ed]
			entry.delay_between = ed.delays[delay_idx]
			wave.entries.append(entry)
			
	return wave


func get_points_pool(wave_index: int) -> int:
	if wave_index < _wave_pools.size():
		return _wave_pools[wave_index]
	else:
		# After 36-th wave (index 35), increase by 300 each wave
		return 6600 + (wave_index - 35) * 300


func get_start_delay(wave_index: int) -> float:
	# wave_index is 0-based. Wave 1 is index 0.
	# "WAZNE Delaye po falach 10/20/30 to zawsze 20s"
	# Wave index 10, 20, 30 are Waves 11, 21, 31.
	if wave_index == 10 or wave_index == 20 or wave_index == 30:
		return 20.0
	
	if wave_index == 0:
		return 20.0 # Before wave 1
	
	if wave_index < 4: # Wave 2, 3, 4
		return 20.0 # Spec says "Delay 20s" before wave 1, assuming same for rest of group
	if wave_index < 6: # Wave 5, 6
		return 15.0
	if wave_index < 8: # Wave 7, 8
		return 10.0
	if wave_index < 10: # Wave 9, 10
		return 9.0
	if wave_index < 14: # Wave 11-14
		return 9.0
	if wave_index < 20: # Wave 15-20
		return 7.0
	if wave_index < 30: # Wave 21-30
		return 5.0
	
	return 4.0 # Wave 31+
