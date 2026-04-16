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
signal magic_cooldown_changed(time_left: float)

@export var max_hp: int = 100
var _hp: int = max_hp
var _scales: int = 100

@export var magic_cost: int = 35
@export var magic_damage: float = 30.0
@export var magic_slow_multiplier: float = 0.6
@export var magic_slow_duration: float = 2.5
@export var magic_cooldown: float = 12.0
var _magic_cooldown_left: float = 0.0

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
	reset()


func _process(delta: float) -> void:
	if _magic_cooldown_left > 0.0:
		_magic_cooldown_left -= delta
		if _magic_cooldown_left < 0.0:
			_magic_cooldown_left = 0.0
		magic_cooldown_changed.emit(_magic_cooldown_left)


func reset() -> void:
	_hp = max_hp
	_scales = 100
	_magic_cooldown_left = 0.0
	hp_changed.emit(_hp)
	scales_changed.emit(_scales)
	magic_cooldown_changed.emit(_magic_cooldown_left)


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


func cast_magic() -> bool:
	if not can_cast_magic():
		return false

	if not spend_scales(magic_cost):
		return false

	_magic_cooldown_left = magic_cooldown
	magic_cooldown_changed.emit(_magic_cooldown_left)
	magic_burst_casted.emit(magic_damage, magic_slow_multiplier, magic_slow_duration)
	return true


func get_magic_cooldown_left() -> float:
	return _magic_cooldown_left


var selected_tower: TowerType = null


func select_tower(tower_type: TowerType) -> void:
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
