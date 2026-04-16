extends Node

signal hp_changed(new_hp: int)
signal scales_changed(new_scales: int)
signal game_over
signal tower_selected(tower_type: TowerType)
signal tower_deselected
signal placed_tower_selected(tower_node: Node2D)
signal placed_tower_deselected
signal wave_start_requested
signal victory
signal magic_burst_casted(damage: float, slow_multiplier: float, slow_duration: float)
signal magic_rebellion_triggered(freeze_duration: float)
signal magic_cooldown_changed(time_left: float)
signal magic_rebellion_changed(chance: float)

@export var max_hp: int = 100
var _hp: int = max_hp
var _scales: int = 100

@export var magic_cost: int = 35
@export var magic_damage: float = 30.0
@export var magic_slow_multiplier: float = 0.6
@export var magic_slow_duration: float = 2.5
@export var magic_cooldown: float = 12.0
@export var magic_rebellion_start_chance: float = 0.05
@export var magic_rebellion_chance_growth: float = 0.07
@export var magic_rebellion_chance_cap: float = 0.65
@export var magic_rebellion_wave_growth: float = 0.04
@export var magic_rebellion_freeze_duration: float = 5.0
@export var magic_purify_cost: int = 20
@export var magic_purify_reduction: float = 0.10
var _magic_cooldown_left: float = 0.0
var _magic_rebellion_corruption: float = 0.0
var _tower_freeze_left: float = 0.0
var _current_wave_index: int = 0

var _magic_rng := RandomNumberGenerator.new()

var hp: int:
	get:
		return _hp
	set(value):
		_hp = clampi(value, 0, max_hp)
		hp_changed.emit(_hp)
		if _hp <= 0:
			game_over.emit()

var scales: int:
	get:
		return _scales
	set(value):
		_scales = maxi(value, 0)
		scales_changed.emit(_scales)


func _ready() -> void:
	_magic_rng.randomize()
	reset()


func _process(delta: float) -> void:
	if _magic_cooldown_left > 0.0:
		_magic_cooldown_left -= delta
		if _magic_cooldown_left < 0.0:
			_magic_cooldown_left = 0.0
		magic_cooldown_changed.emit(_magic_cooldown_left)

	if _tower_freeze_left > 0.0:
		_tower_freeze_left -= delta
		if _tower_freeze_left < 0.0:
			_tower_freeze_left = 0.0


func reset() -> void:
	_hp = max_hp
	_scales = 100
	_magic_cooldown_left = 0.0
	_magic_rebellion_corruption = 0.0
	_tower_freeze_left = 0.0
	_current_wave_index = 0
	hp_changed.emit(_hp)
	scales_changed.emit(_scales)
	magic_cooldown_changed.emit(_magic_cooldown_left)
	magic_rebellion_changed.emit(get_magic_rebellion_chance())


func take_damage(amount: int) -> void:
	hp -= amount


func heal(amount: int) -> void:
	hp += amount


func add_scales(amount: int) -> void:
	scales += amount


func spend_scales(amount: int) -> bool:
	if _scales >= amount:
		scales -= amount
		return true
	return false


func can_afford(amount: int) -> bool:
	return _scales >= amount


func can_cast_magic() -> bool:
	return _magic_cooldown_left <= 0.0 and can_afford(magic_cost)


func set_current_wave_index(wave_index: int) -> void:
	_current_wave_index = maxi(wave_index, 0)
	magic_rebellion_changed.emit(get_magic_rebellion_chance())


func get_current_wave_index() -> int:
	return _current_wave_index


func get_magic_rebellion_chance() -> float:
	return clampf(
		magic_rebellion_start_chance
		+ float(_current_wave_index) * magic_rebellion_wave_growth
		+ _magic_rebellion_corruption,
		0.0,
		magic_rebellion_chance_cap
	)


func _get_magic_rebellion_base_chance() -> float:
	return clampf(
		magic_rebellion_start_chance + float(_current_wave_index) * magic_rebellion_wave_growth,
		0.0,
		magic_rebellion_chance_cap
	)


func cast_magic() -> bool:
	if not can_cast_magic():
		return false

	if not spend_scales(magic_cost):
		return false

	_magic_cooldown_left = magic_cooldown
	magic_cooldown_changed.emit(_magic_cooldown_left)
	var rebel_chance := get_magic_rebellion_chance()
	var rebelled := _magic_rng.randf() < rebel_chance
	_magic_rebellion_corruption = min(
		magic_rebellion_chance_cap,
		_magic_rebellion_corruption + magic_rebellion_chance_growth
	)
	magic_rebellion_changed.emit(get_magic_rebellion_chance())
	if rebelled:
		_tower_freeze_left = magic_rebellion_freeze_duration
		magic_rebellion_triggered.emit(magic_rebellion_freeze_duration)
	else:
		magic_burst_casted.emit(magic_damage, magic_slow_multiplier, magic_slow_duration)
	return true


func can_purify_magic() -> bool:
	if not can_afford(magic_purify_cost):
		return false
	var base_chance := _get_magic_rebellion_base_chance()
	return get_magic_rebellion_chance() - base_chance > 0.0001


func purify_magic() -> bool:
	if not can_purify_magic():
		return false

	if not spend_scales(magic_purify_cost):
		return false

	var before_chance := get_magic_rebellion_chance()
	_magic_rebellion_corruption = maxf(0.0, _magic_rebellion_corruption - magic_purify_reduction)

	# If we were clamped by the cap, force a visible drop when there is still reducible corruption.
	var after_chance := get_magic_rebellion_chance()
	if before_chance - after_chance < 0.005 and before_chance >= magic_rebellion_chance_cap:
		var base_chance := _get_magic_rebellion_base_chance()
		var target_visible := maxf(base_chance, magic_rebellion_chance_cap - 0.01)
		var needed_corruption := maxf(0.0, target_visible - base_chance)
		if _magic_rebellion_corruption > needed_corruption:
			_magic_rebellion_corruption = needed_corruption
			after_chance = get_magic_rebellion_chance()

	if after_chance >= before_chance:
		# Safety rollback: do not charge if purification could not reduce current chance.
		add_scales(magic_purify_cost)
		return false

	magic_rebellion_changed.emit(get_magic_rebellion_chance())
	return true


func get_magic_cooldown_left() -> float:
	return _magic_cooldown_left


func is_towers_frozen() -> bool:
	return _tower_freeze_left > 0.0


func get_tower_freeze_left() -> float:
	return _tower_freeze_left


func get_magic_purify_cost() -> int:
	return magic_purify_cost


func get_magic_purify_reduction() -> float:
	return magic_purify_reduction


var selected_tower: TowerType = null


func select_tower(tower_type: TowerType) -> void:
	if selected_placed_tower:
		deselect_placed_tower()
	selected_tower = tower_type
	tower_selected.emit(tower_type)


func deselect_tower() -> void:
	selected_tower = null
	tower_deselected.emit()


var selected_placed_tower: Node2D = null


func select_placed_tower(tower_node: Node2D) -> void:
	if selected_placed_tower == tower_node:
		return
	deselect_placed_tower()
	deselect_tower()
	selected_placed_tower = tower_node
	placed_tower_selected.emit(tower_node)


func deselect_placed_tower() -> void:
	if selected_placed_tower:
		selected_placed_tower = null
		placed_tower_deselected.emit()
