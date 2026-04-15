extends Control

@onready var main_buttons: VBoxContainer = %MainButtons
@onready var settings_panel: PanelContainer = %SettingsPanel


func _ready() -> void:
	%ResumeButton.pressed.connect(_on_resume_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%MainMenuButton.pressed.connect(_on_main_menu_pressed)
	%ExitButton.pressed.connect(_on_exit_pressed)
	settings_panel.back_pressed.connect(_on_settings_back)

	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_unpause()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	settings_panel.hide()
	main_buttons.show()
	visible = true
	get_tree().paused = true


func _unpause() -> void:
	visible = false
	get_tree().paused = false


func _on_resume_pressed() -> void:
	_unpause()


func _on_settings_pressed() -> void:
	main_buttons.hide()
	settings_panel.refresh()
	settings_panel.show()


func _on_main_menu_pressed() -> void:
	_unpause()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_settings_back() -> void:
	settings_panel.hide()
	main_buttons.show()
