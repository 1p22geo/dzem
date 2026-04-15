extends Tile

@export var tower:TowerType


var controller:EnemyController;


func _ready() -> void:
	controller = get_parent().get_parent().get_node("EnemyController")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func FindClosestEnemyToAttack() -> Enemy:
	var closestEnemy: Enemy;
	for enemy in controller.activeEnemies:
		var x_pos = enemy.position.x
		var y_pos = enemy.position.y
		var x_diff = abs(x_pos - )
		
		
	return closestEnemy
	
