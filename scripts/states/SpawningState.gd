extends State
class_name SpawningState

var timer: float = 0.0
var controller: Node
var _victory_emitted: bool = false

var _current_entry_index: int = 0
var _current_entry_spawned: int = 0


func _ready() -> void:
	controller = get_parent().get_parent()


func Enter() -> void:
	controller.enemies_spawned = 0
	_current_entry_index = 0
	_current_entry_spawned = 0
	timer = 0.0
	_victory_emitted = false


func Update(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return
	timer = 0.0

	if controller.spawner == null:
		push_warning("SpawningState: controller.spawner is null")
		return

	if not controller.ensure_wave_exists(controller.wave_no):
		if not _victory_emitted and controller.activeEnemies.is_empty():
			_victory_emitted = true
			GameManager.victory.emit()
		return

	var wave: Wave = controller.waveDefs.waves[controller.wave_no]

	if not wave.entries.is_empty():
		_spawn_from_entries(wave)
	else:
		_spawn_legacy(wave)


func _spawn_from_entries(wave: Wave) -> void:
	if _current_entry_index < wave.entries.size():
		var entry = wave.entries[_current_entry_index]
		if _current_entry_spawned < entry.count:
			var enemy = controller.spawner.spawn_enemy(entry.enemy_type)
			controller.register_enemy(enemy)
			_current_entry_spawned += 1
			controller.enemies_spawned += 1
			timer = entry.delay_between
		else:
			_current_entry_index += 1
			_current_entry_spawned = 0
			# Wait for next frame to check next entry
	else:
		_finish_wave()


func _spawn_legacy(wave: Wave) -> void:
	if controller.enemies_spawned < wave.enemy_count:
		var enemy = controller.spawner.spawn_enemy(wave.enemy_type)
		controller.register_enemy(enemy)
		controller.enemies_spawned += 1
		timer = wave.delay_between_enemies
	else:
		_finish_wave()


func _finish_wave() -> void:
	controller.wave_no += 1
	if controller.ensure_wave_exists(controller.wave_no):
		Change.emit(self, "WaitingForWaveState")
