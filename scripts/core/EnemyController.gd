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
	prepare_states()
	
