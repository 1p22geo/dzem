extends State
class_name WaitingForWaveState

var timer: float = 0.0
var controller: Node


func _ready() -> void:
	controller = get_parent().get_parent()


func Enter() -> void:
	var wave: Wave = controller.waveDefs.waves[controller.wave_no]
	timer = wave.start_delay


func Update(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		Change.emit(self, "SpawningState")
