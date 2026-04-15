extends Node2D

class_name Enemy

@export var type:EnemyType

signal reached_base(enemy: Enemy)
var hp:float;

var current_tile:Road

var target: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if type != null:
		$Sprite2D.texture = type.texture
		hp = type.health;
		

func _process(delta: float) -> void:
	target = current_tile.next
	if target == null:
		reached_base.emit(self)
		queue_free()
		return

	var speed := 0.0
	if type != null:
		speed = type.speed

	global_position = global_position.move_toward(target.global_position, speed * delta)

	if global_position.distance_to(target.global_position) <= 4.0:
		current_tile = target
		
	if hp <= 0:
		queue_free()
		print("enemy killed")
