extends Road

class_name Spawner

@export var enemy_template:PackedScene;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func spawn_enemy(enemy: EnemyType) -> void:
	var child:Enemy = enemy_template.instantiate()
	child.type = enemy
	get_parent().get_parent().add_child(child)
