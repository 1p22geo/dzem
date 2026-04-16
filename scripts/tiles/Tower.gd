extends Tile

class_name Tower

@export var tower:TowerType


var controller:EnemyController;
var tower_sprite:Sprite2D;
var timer = 0
var selected: bool = false

var active_projectiles = []

var _sweep_alpha: float = 0.0
var _sweep_dir: Vector2 = Vector2.RIGHT
var _sweep_half_angle: float = 0.0
var _sweep_radius: float = 0.0

@onready var projectile_scene:PackedScene = load("res://scenes/entities/Projectile.tscn")

func _ready() -> void:
	var scene_root := get_tree().current_scene
	controller = scene_root.find_child(
		"EnemyController", true, false
	) as EnemyController
	tower_sprite = get_node("TowerSprite")
	GameManager.placed_tower_selected.connect(
		_on_placed_tower_selected
	)
	GameManager.placed_tower_deselected.connect(
		_on_placed_tower_deselected
	)
	tower_sprite.hframes = 7
	if scene_root != null:
		controller = scene_root.find_child(
			"EnemyController", true, false
		) as EnemyController
	if has_node("TowerSprite"):
		tower_sprite = get_node("TowerSprite")
	if not GameManager.placed_tower_selected.is_connected(_on_placed_tower_selected):
		GameManager.placed_tower_selected.connect(_on_placed_tower_selected)
	if not GameManager.placed_tower_deselected.is_connected(_on_placed_tower_deselected):
		GameManager.placed_tower_deselected.connect(_on_placed_tower_deselected)


func _on_placed_tower_selected(t: Node2D) -> void:
	selected = (t == self)
	queue_redraw()


func _on_placed_tower_deselected() -> void:
	selected = false
	queue_redraw()


func _draw() -> void:
	if _sweep_alpha > 0.0:
		_draw_sweep()
	if not selected or not tower:
		return
	var radius := float(tower.attackRange)
	draw_circle(Vector2.ZERO, radius, Color(0, 0, 0, 0.25))
	draw_arc(
		Vector2.ZERO, radius, 0, TAU, 64,
		Color(1, 1, 1, 0.6), 3.0
	)


func _draw_sweep() -> void:
	var center_angle := _sweep_dir.angle()
	var half := _sweep_half_angle
	var r := _sweep_radius
	var segments := 24
	var color_fill := Color(1.0, 0.7, 0.1, _sweep_alpha * 0.55)
	var color_edge := Color(1.0, 0.95, 0.4, _sweep_alpha * 0.9)

	var points: PackedVector2Array = [Vector2.ZERO]
	for i in range(segments + 1):
		var angle := center_angle - half + (2.0 * half * float(i) / float(segments))
		points.append(Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color_fill)
	draw_arc(Vector2.ZERO, r, center_angle - half, center_angle + half, segments, color_edge, 4.0)


func _process(delta: float) -> void:
	if tower == null or controller == null or tower_sprite == null:
		return
	if _sweep_alpha > 0.0:
		_sweep_alpha -= delta * 1.5
		if _sweep_alpha <= 0.0:
			_sweep_alpha = 0.0
		queue_redraw()

	timer += delta
	if timer > tower.fire_delay:
		timer = 0
		var closestEnemy:Enemy = FindClosestEnemyToAttack()
		if tower.is_melee:
			MeleeAttack(closestEnemy)
		else:
			AttackEnemy(closestEnemy)

func FindClosestEnemyToAttack() -> Enemy:
	if tower and controller:
		var closestEnemy: Enemy
		var tower_pos := tower_sprite.global_position
		var max_distsance = -1
		for enemy in controller.activeEnemies:
			if not is_instance_valid(enemy):
				continue
			if enemy.hp <= 0:
				continue

			var diff = tower_pos.distance_to(enemy.global_position)
			var dist = enemy.distance
			
			if dist > max_distsance && diff <= tower.attackRange:
				max_distsance = dist
				closestEnemy = enemy
		return closestEnemy
	return null


func MeleeAttack(target_enemy: Enemy) -> void:
	if target_enemy == null:
		return
	if not is_instance_valid(target_enemy):
		return

	var tower_pos := tower_sprite.global_position
	var dir_to_target := (target_enemy.global_position - tower_pos).normalized()
	var half_angle := deg_to_rad(tower.sweep_angle * 0.5)

	_sweep_dir = dir_to_target
	_sweep_half_angle = half_angle
	_sweep_radius = float(tower.attackRange)
	_sweep_alpha = 1.0
	queue_redraw()

	for enemy in controller.activeEnemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.hp <= 0:
			continue
		var to_enemy := enemy.global_position - tower_pos
		var dist := to_enemy.length()
		if dist > tower.attackRange:
			continue
		var angle_diff := absf(dir_to_target.angle_to(to_enemy.normalized()))
		if angle_diff <= half_angle:
			var enemy_armor: float = 0.0
			if enemy.type != null:
				enemy_armor = enemy.type.armor
			var final_damage: float = tower.damage - enemy_armor
			if final_damage < 1.0:
				final_damage = 1.0
			enemy.hp -= final_damage


func AttackEnemy(enemy:Enemy) -> void:
	if tower:
		if enemy == null:
			return
		if not is_instance_valid(enemy):
			return
		if enemy.hp <= 0:
			return
		if len(active_projectiles) >= tower.max_projectiles:
			return
			
		var spawned_projectile:Projectile = projectile_scene.instantiate()
		spawned_projectile.damage = tower.damage
		spawned_projectile.speed = tower.projectile_speed
		spawned_projectile.target = enemy
		spawned_projectile.parent_tower = self
		spawned_projectile.get_node("Sprite2D").texture = tower.projectile_texture
		spawned_projectile.global_position = global_position
		spawned_projectile.z_index = 1
		active_projectiles.append(spawned_projectile)
		get_tree().current_scene.add_child(spawned_projectile)
