extends Tile

@export var tower:TowerType


var controller:EnemyController;
var tower_sprite:Sprite2D;

func _ready() -> void:
	controller = get_parent().get_parent().get_parent().get_node("EnemyController")
	tower_sprite = get_node("TowerSprite")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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
		
		if diff < min_diff:
			min_diff = diff
			closestEnemy = enemy
	if (controller.activeEnemies.size() > 0):
		return closestEnemy
	else:
		return null
		
func AttackEnemy(enemy:Enemy) -> void:
	pass
	
