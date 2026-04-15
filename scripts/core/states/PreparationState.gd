extends State
class_name PreparationState

var timer: float = 0.0
var controller: Node


func _ready() -> void:
	controller = get_parent().get_parent()


func Enter() -> void:
	timer = controller.waveDefs.preparation_time
	print(timer)

func Update(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		timer = 0.0
		Change.emit(self, "WaitingForWaveState")
		return
