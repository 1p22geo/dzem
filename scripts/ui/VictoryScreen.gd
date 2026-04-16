extends Control

@onready var stats_label: Label = %StatsLabel
@onready var menu_btn: Button = %MainMenuButton
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	menu_btn.pressed.connect(_on_main_menu)
	GameManager.victory.connect(_on_victory)


func _on_victory() -> void:
	var hp_left := GameManager.hp
	var scales_left := GameManager.scales
	stats_label.text = "HP: %d  |  Luski: %d" % [hp_left, scales_left]
	visible = true
	get_tree().paused = true
	_animate_in()


func _animate_in() -> void:
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	stats_label.modulate.a = 0.0
	menu_btn.modulate.a = 0.0

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(title_label, "modulate:a", 1.0, 0.8)
	tw.tween_property(subtitle_label, "modulate:a", 1.0, 0.5)
	tw.tween_property(stats_label, "modulate:a", 1.0, 0.4)
	tw.tween_property(menu_btn, "modulate:a", 1.0, 0.3)


func _on_main_menu() -> void:
	get_tree().paused = false
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
