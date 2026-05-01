extends EnemyController

class_name EndlessEnemyController

@export var initial_scales: int = 250
@export var base_enemy_count: int = 8
@export var enemy_count_growth: float = 1.25
@export var initial_spawn_delay: float = 0.8
@export var min_spawn_delay: float = 0.12
@export var spawn_delay_decay: float = 0.015
@export var initial_start_delay: float = 3.0
@export var min_start_delay: float = 1.0
@export var start_delay_decay: float = 0.05

var _wave_rng := RandomNumberGenerator.new()
var _generated_waves: int = 0

var _enemy_pool: Array[EnemyType] = [
	preload("res://resources/enemy_defs/TestEnemy.tres"),
	preload("res://resources/enemy_defs/FastEnemy.tres"),
	preload("res://resources/enemy_defs/StrongEnemy.tres"),
	preload("res://resources/enemy_defs/TankEnemy.tres"),
	preload("res://resources/enemy_defs/EliteEnemy.tres")
]


func _ready() -> void:
	_wave_rng.randomize()
	if waveDefs == null:
		waveDefs = Waves.new()
	waveDefs.waves.clear()
	waveDefs.initial_coins = initial_scales
	_generated_waves = 0
	ensure_wave_exists(0)
	super._ready()


func ensure_wave_exists(wave_index: int) -> bool:
	if wave_index < 0:
		return false
	if waveDefs == null:
		waveDefs = Waves.new()
	while waveDefs.waves.size() <= wave_index:
		waveDefs.waves.append(_build_wave(_generated_waves))
		_generated_waves += 1
	return true


func is_endless_mode() -> bool:
	return true


func _build_wave(wave_index: int) -> Wave:
	var wave := Wave.new()
	var intensity := float(wave_index)

	wave.enemy_type = _pick_enemy_type(wave_index)
	wave.enemy_count = maxi(1, int(round(base_enemy_count + intensity * enemy_count_growth)))
	wave.delay_between_enemies = maxf(
		min_spawn_delay,
		initial_spawn_delay - intensity * spawn_delay_decay
	)
	wave.start_delay = maxf(
		min_start_delay,
		initial_start_delay - intensity * start_delay_decay
	)
	return wave


func _pick_enemy_type(wave_index: int) -> EnemyType:
	if _enemy_pool.is_empty():
		return null

	if (wave_index + 1) % 12 == 0 and _enemy_pool.size() >= 5:
		return _enemy_pool[4]
	if (wave_index + 1) % 8 == 0 and _enemy_pool.size() >= 4:
		return _enemy_pool[3]

	var unlocked := mini(2 + wave_index / 6, _enemy_pool.size())
	var idx := _wave_rng.randi_range(0, unlocked - 1)
	return _enemy_pool[idx]
