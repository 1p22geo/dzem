extends Button

@export var play_icon: Texture2D
@export var pause_icon: Texture2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pressed.connect(_on_pressed)
	if play_icon:
		icon = play_icon


func _process(_delta: float) -> void:
	if _is_spawning():
		icon = pause_icon if pause_icon else play_icon
	else:
		icon = play_icon


func _on_pressed() -> void:
	if _is_spawning():
		var pause_menu := _get_pause_menu()
		if pause_menu:
			if pause_menu.visible:
				pause_menu.unpause()
			else:
				pause_menu.pause()
	else:
		GameManager.wave_start_requested.emit()


func _is_spawning() -> bool:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return false
	var ec := scene_root.find_child(
		"EnemyController", true, false
	) as EnemyController
	if ec and ec.state and ec.state.current_state:
		return ec.state.current_state is SpawningState
	return false


func _get_pause_menu() -> Control:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return null
	return scene_root.find_child("PauseMenu", true, false) as Control
