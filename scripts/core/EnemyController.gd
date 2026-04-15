extends Node

class_name EnemyController

@export var spawner: Spawner
@export var waveDefs: Waves

var wave_no: int = 0
var enemies_spawned: int = 0

var state: StateMachine

var activeEnemies:Array[Enemy] = []



func prepare_states() -> void:
	var sm = StateMachine.new()
	sm.name = "StateMachine"

	var prep = PreparationState.new()
	prep.name = "PreparationState"
	sm.add_child(prep)

	var waiting = WaitingForWaveState.new()
	waiting.name = "WaitingForWaveState"
	sm.add_child(waiting)

	var spawning = SpawningState.new()
	spawning.name = "SpawningState"
	sm.add_child(spawning)

	sm.initial_state = prep
	add_child(sm)
	state = sm


func _ready() -> void:
	if spawner == null:
		var scene_root := get_tree().current_scene
		if scene_root != null:
			spawner = scene_root.find_child("Spawner", true, false) as Spawner

	prepare_states()


func register_enemy(enemy: Enemy) -> void:
	if enemy == null:
		return

	activeEnemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))


func _on_enemy_removed(enemy: Enemy) -> void:
	activeEnemies.erase(enemy)
