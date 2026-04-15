extends Node

@export var spawner:Spawner;
@export var waveDefs: Waves;

var time:float = 0;
var wave_no = 0;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func should_wave_begin() -> bool:
	var next_wave_time = waveDefs.preparation_time


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	
	
