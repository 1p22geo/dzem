extends Tile

@export var tower:TowerType


var controller:EnemyController;
var tower_sprite:Sprite2D;
var range: int
var cost: int 
var texture: Texture
var demage: int
var tower_name: String

func _ready() -> void:
	controller = get_parent().get_parent().get_parent().get_node("EnemyController")
	tower_sprite = get_node("TowerSprite")
	range = tower.range
	cost = tower.cost
	demage = tower.demage
	tower_name = tower.name
	texture = tower.texture

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var closestEnemy:Enemy = FindClosestEnemyToAttack()
	AttackEnemy(closestEnemy)

func FindClosestEnemyToAttack() -> Enemy:
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
		
		if diff < min_diff && diff <= range:
			min_diff = diff
			closestEnemy = enemy
	if (controller.activeEnemies.size() > 0):
		print("enemy found")
		return closestEnemy
	else:
		return null
		
func AttackEnemy(enemy:Enemy) -> void:
	if enemy == null:
		return 
	enemy.hp -= demage
	
