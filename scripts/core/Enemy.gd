extends Node2D

class_name Enemy

@export var type: EnemyType

signal reached_base(enemy: Enemy)
var hp: float

var path: PackedVector2Array
var path_index: int = 0
var distance: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	if type != null:
		$Sprite2D.texture = type.texture
		hp = type.health


func _process(delta: float) -> void:
	if hp <= 0:
		queue_free()
		return

	if path.is_empty() or path_index >= path.size():
		reached_base.emit(self)
		queue_free()
		return

	var speed := 0.0
	if type != null:
		speed = type.speed

	var target_pos := path[path_index]
	global_position = global_position.move_toward(
		target_pos, speed * delta
	)
	distance += speed * delta

	if global_position.distance_to(target_pos) <= 4.0:
		path_index += 1
