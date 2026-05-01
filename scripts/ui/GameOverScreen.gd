extends Control

@onready var wave_info: Label = %WaveInfo
@onready var retry_btn: Button = %RetryButton
@onready var menu_btn: Button = %MainMenuButton
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_main_menu)
	GameManager.game_over.connect(_on_game_over)


func _on_game_over() -> void:
	var wave_text := _get_wave_text()
	wave_info.text = wave_text
	visible = true
	get_tree().paused = true
	_animate_in()


func _get_wave_text() -> String:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return ""
	var ec := scene_root.find_child(
		"EnemyController", true, false
	) as EnemyController
	if ec and ec.waveDefs:
		if ec.is_endless_mode():
			return "Przetrwales do fali %d" % [ec.wave_no + 1]
		var total: int = ec.waveDefs.waves.size()
		return "Dotarles do fali %d z %d" % [ec.wave_no + 1, total]
	return ""


func _animate_in() -> void:
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	wave_info.modulate.a = 0.0
	retry_btn.modulate.a = 0.0
	menu_btn.modulate.a = 0.0

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(title_label, "modulate:a", 1.0, 0.6)
	tw.tween_property(subtitle_label, "modulate:a", 1.0, 0.4)
	tw.tween_property(wave_info, "modulate:a", 1.0, 0.4)
	tw.tween_property(retry_btn, "modulate:a", 1.0, 0.3)
	tw.tween_property(menu_btn, "modulate:a", 1.0, 0.3)


func _on_retry() -> void:
	get_tree().paused = false
	GameManager.reset()
	get_tree().reload_current_scene()


func _on_main_menu() -> void:
	get_tree().paused = false
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
