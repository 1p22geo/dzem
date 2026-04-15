extends Node2D

class_name Projectile

var target:Enemy;
var speed:float;
var damage:float;
var flight_direction: Vector2 = Vector2.RIGHT
const DESPAWN_MARGIN := 64.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(target):
		var target_vector := target.global_position - global_position
		if target_vector != Vector2.ZERO:
			flight_direction = target_vector.normalized()
	else:
		queue_free()
		return

	global_position += flight_direction * speed * delta

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if enemy.hp <= 0:
			continue
		if global_position.distance_to(enemy.global_position) <= 4.0:
			enemy.hp -= damage
			queue_free()
			return

	var viewport_rect := get_viewport_rect().grow(DESPAWN_MARGIN)
	if not viewport_rect.has_point(global_position):
		queue_free()
