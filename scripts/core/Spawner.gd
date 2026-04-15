extends Tile

class_name Spawner

@export var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
@export var spawn_parent_path: NodePath

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func spawn_enemy(enemy_type: EnemyType) -> Enemy:
	if enemy_scene == null:
		push_warning("Spawner: enemy_scene is not assigned")
		return null

	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		push_warning("Spawner: enemy_scene must instantiate Enemy")
		return null

	enemy.type = enemy_type
	enemy.global_position = global_position

	var spawn_parent := _resolve_spawn_parent()
	spawn_parent.add_child(enemy)
	return enemy


func _resolve_spawn_parent() -> Node:
	if spawn_parent_path != NodePath():
		var by_path := get_node_or_null(spawn_parent_path)
		if by_path != null:
			return by_path

	var root := get_tree().current_scene
	if root != null:
		return root

	return self
