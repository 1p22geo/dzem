extends Tile

@export var tower:TowerType


var controller:EnemyController;
var tower_sprite:Sprite2D;
var timer = 0

@onready var projectile_scene:PackedScene = load("res://scenes/Projectile.tscn")

func _ready() -> void:
	controller = get_parent().get_parent().get_parent().get_node("EnemyController")
	tower_sprite = get_node("TowerSprite")


func _process(delta: float) -> void:
	timer+=delta
	if timer > tower.fire_delay: 
		timer = 0
		var closestEnemy:Enemy = FindClosestEnemyToAttack()
		AttackEnemy(closestEnemy)

func FindClosestEnemyToAttack() -> Enemy:
	if tower:
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
			
		var spawned_projectile:Projectile = projectile_scene.instantiate()
		spawned_projectile.damage = tower.damage
		spawned_projectile.speed = tower.projectile_speed
		spawned_projectile.target = enemy
		spawned_projectile.get_node("Sprite2D").texture = tower.projectile_texture
		spawned_projectile.global_position = global_position
		spawned_projectile.z_index = 1
		get_parent().get_parent().get_parent().add_child(spawned_projectile)
