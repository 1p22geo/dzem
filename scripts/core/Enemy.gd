extends Node2D

class_name Enemy

@export var type:EnemyType

signal reached_base(enemy: Enemy)
var hp:float;

var target: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if type != null:
		$Sprite2D.texture = type.texture
		hp = type.health;
		

	target = _find_base()
	if target == null:
		push_warning("Enemy: base target not found")



func _process(delta: float) -> void:
	if target == null:
		return

	var speed := 0.0
	if type != null:
		speed = type.speed

	global_position = global_position.move_toward(target.global_position, speed * delta)

	if global_position.distance_to(target.global_position) <= 4.0:
		reached_base.emit(self)
		queue_free()
	if hp <= 0:
		queue_free()
		print("enemy killed")


func _find_base() -> Node2D:
	var base_group := get_tree().get_first_node_in_group("base")
	if base_group is Node2D:
		return base_group

	var root := get_tree().current_scene
	if root == null:
		return null

	var base_node := root.find_child("Base", true, false)
	if base_node is Node2D:
		return base_node

	return null
