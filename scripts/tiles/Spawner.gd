extends Node2D

class_name Spawner

@export var enemy_template: PackedScene = preload("res://scenes/entities/Enemy.tscn")

var tile_map: TileMapManager
var base_position: Vector2


func _ready() -> void:
	var scene_root := get_tree().current_scene
	tile_map = scene_root.find_child(
		"TileMapLayer", true, false
	) as TileMapManager
	var base_node := scene_root.find_child(
		"Base", true, false
	)
	if base_node:
		base_position = base_node.global_position


func spawn_enemy(enemy_type: EnemyType) -> Enemy:
	if enemy_template == null:
		push_warning("Spawner: enemy_template is null")
		return null

	var child := enemy_template.instantiate() as Enemy
	if child == null:
		push_warning("Spawner: did not create an Enemy")
		return null

	child.type = enemy_type
	child.global_position = global_position
	child.path = tile_map.get_enemy_path(
		global_position, base_position
	)
	get_tree().current_scene.add_child(child)
	return child
