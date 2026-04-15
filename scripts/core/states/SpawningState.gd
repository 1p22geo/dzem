extends State
class_name SpawningState

var timer: float = 0.0
var controller: Node


func _ready() -> void:
	controller = get_parent().get_parent()


func Enter() -> void:
	controller.enemies_spawned = 0
	timer = 0.0


func Update(delta: float) -> void:
	timer -= delta
	print(timer)
	if timer > 0.0:
		return
	timer = 0.0

	var wave: Wave = controller.waveDefs.waves[controller.wave_no]

	if controller.enemies_spawned < wave.enemy_count:
		print(controller.spawner)
		controller.spawner.spawn_enemy(wave.enemy_type)
		controller.enemies_spawned += 1
		timer = wave.delay_between_enemies
	else:
		controller.wave_no += 1
		if controller.wave_no < controller.waveDefs.waves.size():
			Change.emit(self, "WaitingForWaveState")
			return
