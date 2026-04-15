extends Node

signal hp_changed(new_hp: int)
signal scales_changed(new_scales: int)
signal game_over

@export var max_hp: int = 100
var _hp: int = max_hp
var _scales: int = 100

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


func reset() -> void:
	_hp = max_hp
	_scales = 100
	hp_changed.emit(_hp)
	scales_changed.emit(_scales)


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
