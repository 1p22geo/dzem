extends Node

@export var spawner: Spawner
@export var waveDefs: Waves

var wave_no: int = 0
var enemies_spawned: int = 0

var state: StateMachine


func _ready() -> void:
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
