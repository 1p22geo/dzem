extends Node

@export var spawner:Spawner;
@export var waveDefs: Waves;

var time:float = 0;
var wave_time:float = 0;
var enemy_time:float = 0;

var wave_no = 0;
var enemies_spawned = 0;

var state : #TODO



func progress_waves() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	
	
