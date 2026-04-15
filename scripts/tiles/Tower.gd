extends Tile

@export var tower:TowerType


var controller:EnemyController;
var tower_sprite:Sprite2D;
var timer = 0

@onready var projectile:PackedScene = load("uid://c7tdsm07l0w3v")

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
		var closestEnemy: Enemy;
		var x_pos = tower_sprite.position.x
		var y_pos = tower_sprite.position.y
		var min_diff = 10000000
		for enemy in controller.activeEnemies:
			var x_pos_enemy = enemy.position.x
			var y_pos_enemy = enemy.position.y
		
			var x_diff = abs(x_pos - x_pos_enemy)
			var y_diff = abs(y_pos - y_pos_enemy)
			
			var diff = sqrt(x_diff*x_diff + y_diff*y_diff)
			
			if diff < min_diff && diff <= tower.range:
				min_diff = diff
				closestEnemy = enemy
		if (controller.activeEnemies.size() > 0):
			print("enemy found")
			return closestEnemy
		else:
			return null
	return null
		
func AttackEnemy(enemy:Enemy) -> void:
	if tower:
		if enemy == null:
			return
			
		var projectile:Projectile = projectile.instantiate()
		projectile.damage = tower.damage
		projectile.speed = tower.projectile_speed
		projectile.target = enemy
		projectile.get_node("Sprite2D").texture = tower.projectile_texture
		projectile.global_position = global_position
		projectile.z_index = 1
		get_parent().get_parent().get_parent().add_child(projectile)
		print("projectile launched")
