extends Tile

class_name Tower

@export var tower:TowerType


var controller:EnemyController;
var tower_sprite:Sprite2D;
var timer = 0
var selected: bool = false

var active_projectiles = []


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
	if not selected or not tower:
		return
	var radius := float(tower.attackRange)
	draw_circle(Vector2.ZERO, radius, Color(0, 0, 0, 0.25))
	draw_arc(
		Vector2.ZERO, radius, 0, TAU, 64,
		Color(1, 1, 1, 0.6), 3.0
	)


func _process(delta: float) -> void:
	if tower == null or controller == null or tower_sprite == null:
		return
	timer+=delta
	if timer > tower.fire_delay: 
		timer = 0
		var closestEnemy:Enemy = FindClosestEnemyToAttack()
		AttackEnemy(closestEnemy)

func FindClosestEnemyToAttack() -> Enemy:
	if tower and controller:
		var closestEnemy: Enemy
		var tower_pos := tower_sprite.global_position
		var min_diff = 10000000
		for enemy in controller.activeEnemies:
			if not is_instance_valid(enemy):
				continue
			if enemy.hp <= 0:
				continue

			var diff = tower_pos.distance_to(enemy.global_position)
			
			if diff < min_diff && diff <= tower.attackRange:
				min_diff = diff
				closestEnemy = enemy
		return closestEnemy
	return null
		
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
