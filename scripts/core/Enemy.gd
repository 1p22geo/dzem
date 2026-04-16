extends Node2D

class_name Enemy

@export var type: EnemyType

signal reached_base(enemy: Enemy)
var hp: float

var path: PackedVector2Array
var path_index: int = 0
var distance: float = 0.0
var damage: float
var prize: int = 0
var prize_granted: bool = false
const TILE_SIZE := 125.0

func _ready() -> void:
	add_to_group("enemies")
	if type != null:
		$Sprite2D.texture = type.texture
		hp = type.health
		damage = type.damage
		prize = type.prize


func _process(delta: float) -> void:
	if hp <= 0:
		if not prize_granted:
			GameManager.add_scales(prize)
			prize_granted = true
		queue_free()
		return

	if path.is_empty() or path_index >= path.size():
		reached_base.emit(self)
		GameManager.take_damage(int(round(damage)))
		queue_free()
		return

	var speed := 0.0
	if type != null:
		speed = type.speed * TILE_SIZE

	var target_pos := path[path_index]
	global_position = global_position.move_toward(
		target_pos, speed * delta
	)
	distance += speed * delta

	if global_position.distance_to(target_pos) <= 4.0:
		path_index += 1
