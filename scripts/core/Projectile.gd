extends Node2D

class_name Projectile

var target:Enemy;
var speed:float;
var damage:float;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	global_position = global_position.move_toward(target.global_position, speed * delta)

	if global_position.distance_to(target.global_position) <= 4.0:
		target.hp -= damage;
		queue_free()
		target = null
		return
