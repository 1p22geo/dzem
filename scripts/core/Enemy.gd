extends Node2D

class_name Enemy

@export var type: EnemyType

signal reached_base(enemy: Enemy)
var hp: float

var path: PackedVector2Array
var path_index: int = 0
var distance: float = 0.0
var damage: float
var prize: int = 0
var prize_granted: bool = false
const TILE_SIZE := 125.0
var slow_multiplier: float = 1.0
var slow_time_left: float = 0.0

@onready var fish_prefab:PackedScene = load("res://scenes/entities/Enemy.tscn")
@onready var explosion_scene:PackedScene = load("res://scenes/effects/ExplosionEffect.tscn")

func _ready() -> void:
	add_to_group("enemies")
	if type != null:
		$Sprite2D.texture = type.texture
		hp = type.health
		damage = type.damage
		prize = type.prize


func _process(delta: float) -> void:
	if slow_time_left > 0.0:
		slow_time_left -= delta
		if slow_time_left <= 0.0:
			slow_time_left = 0.0
			slow_multiplier = 1.0

	if hp <= 0:
		if not prize_granted:
			GameManager.add_scales(prize)
			prize_granted = true
			for fish_type in type.spawnedEnemies:
				var fish:Enemy = fish_prefab.instantiate()
				fish.type = fish_type
				fish.global_position = global_position
				fish.path = path
				fish.path_index = path_index
				fish.distance = distance
				var controller:EnemyController = get_parent().get_node("EnemyController")
				controller.register_enemy(fish)
				get_parent().add_child(fish)
		_spawn_explosion()
		queue_free()
		return

	if path.is_empty() or path_index >= path.size():
		reached_base.emit(self)
		GameManager.take_damage(int(round(damage)))
		queue_free()
		return

	var speed := 0.0
	if type != null:
		speed = type.speed * TILE_SIZE * slow_multiplier

	var target_pos := path[path_index]
	global_position = global_position.move_toward(
		target_pos, speed * delta
	)
	distance += speed * delta

	if global_position.distance_to(target_pos) <= 4.0:
		path_index += 1


func _spawn_explosion() -> void:
	var fx := explosion_scene.instantiate()
	fx.global_position = global_position
	get_tree().current_scene.add_child(fx)
func apply_magic_slow(multiplier: float, duration: float) -> void:
	if multiplier <= 0.0:
		return

	if multiplier < slow_multiplier:
		slow_multiplier = multiplier

	if duration > slow_time_left:
		slow_time_left = duration
