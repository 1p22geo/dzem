extends Control

@onready var main_buttons: VBoxContainer = %MainButtons
@onready var settings_panel: PanelContainer = %SettingsPanel


func _ready() -> void:
	%PlayButton.pressed.connect(_on_play_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%ExitButton.pressed.connect(_on_exit_pressed)
	settings_panel.back_pressed.connect(_on_settings_back)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/maps/Level1.tscn")


func _on_settings_pressed() -> void:
	main_buttons.hide()
	settings_panel.refresh()
	settings_panel.show()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_settings_back() -> void:
	settings_panel.hide()
	main_buttons.show()
