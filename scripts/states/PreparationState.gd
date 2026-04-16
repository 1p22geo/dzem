extends State
class_name PreparationState

var timer: float = 0.0
var controller: Node


func _ready() -> void:
	controller = get_parent().get_parent()


func Enter() -> void:
	timer = controller.waveDefs.preparation_time
	if not GameManager.wave_start_requested.is_connected(_on_wave_start):
		GameManager.wave_start_requested.connect(_on_wave_start)


func Exit() -> void:
	if GameManager.wave_start_requested.is_connected(_on_wave_start):
		GameManager.wave_start_requested.disconnect(_on_wave_start)


func _on_wave_start() -> void:
	timer = 0.0


func Update(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		timer = 0.0
		Change.emit(self, "WaitingForWaveState")
		return
