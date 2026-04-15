extends Road

class_name Spawner

@export var enemy_template: PackedScene = preload("res://scenes/Enemy.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func spawn_enemy(enemy: EnemyType) -> Enemy:
	if enemy_template == null:
		push_warning("Spawner: enemy_template is null")
		return null

	var child := enemy_template.instantiate() as Enemy
	if child == null:
		push_warning("Spawner: enemy_template did not create an Enemy")
		return null

	child.type = enemy
	get_parent().get_parent().add_child(child)
	return child
