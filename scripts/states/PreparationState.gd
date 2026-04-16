extends State
class_name PreparationState

var controller: Node
var _started: bool = false


func _ready() -> void:
	controller = get_parent().get_parent()


func Enter() -> void:
	_started = false
	if not GameManager.wave_start_requested.is_connected(_on_wave_start):
		GameManager.wave_start_requested.connect(_on_wave_start)


func Exit() -> void:
	if GameManager.wave_start_requested.is_connected(_on_wave_start):
		GameManager.wave_start_requested.disconnect(_on_wave_start)


func _on_wave_start() -> void:
	_started = true


func Update(_delta: float) -> void:
	if _started:
		Change.emit(self, "WaitingForWaveState")
		return
