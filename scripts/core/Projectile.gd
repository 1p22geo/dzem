extends Node2D

class_name Projectile

var target:Enemy;
var speed:float;
var damage:float;
var parent_tower:Tower
var flight_direction: Vector2 = Vector2.RIGHT
var origin_pos: Vector2
var max_range: float = 0.0
const DESPAWN_MARGIN := 64.0

var is_piercing: bool = false
var hit_enemies: Array[Enemy] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func remove_projectile() -> void:
	if is_instance_valid(parent_tower):
		var index := parent_tower.active_projectiles.find(self)
		if index >= 0:
			parent_tower.active_projectiles.remove_at(index)
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(target):
		var target_vector := target.global_position - global_position
		if target_vector != Vector2.ZERO:
			flight_direction = target_vector.normalized()
	elif not is_piercing:
		remove_projectile()
		return

	global_position += flight_direction * speed * delta

	if max_range > 0.0 and global_position.distance_to(origin_pos) > max_range:
		remove_projectile()
		return

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if enemy.hp <= 0:
			continue
		if hit_enemies.has(enemy):
			continue
			
		if global_position.distance_to(enemy.global_position) <= 32.0:
			var enemy_armor: float = 0.0
			if enemy.type != null:
				enemy_armor = enemy.type.armor
			var final_damage: float = damage - enemy_armor
			if final_damage < 1.0:
				final_damage = 1.0
			
			_on_impact(enemy, final_damage)
			
			if not is_piercing:
				remove_projectile()
				return
			else:
				hit_enemies.append(enemy)

	var viewport_rect := get_viewport_rect().grow(DESPAWN_MARGIN)
	if not viewport_rect.has_point(global_position):
		remove_projectile()


func _on_impact(enemy: Enemy, final_damage: float) -> void:
	enemy.take_damage(final_damage)
	if is_instance_valid(parent_tower):
		parent_tower.total_damage_dealt += final_damage
		if enemy.hp <= 0:
			parent_tower.on_enemy_killed()
		
		# Tower-specific on-hit effects can be called here or in Tower.gd
		if parent_tower.has_method("_on_projectile_impact"):
			parent_tower._on_projectile_impact(enemy, self)
