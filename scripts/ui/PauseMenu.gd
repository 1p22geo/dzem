extends Control

@onready var main_buttons: VBoxContainer = %MainButtons
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var volume_slider: HSlider = %VolumeSlider
@onready var fullscreen_check: CheckButton = %FullscreenCheck


func _ready() -> void:
	%ResumeButton.pressed.connect(_on_resume_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%MainMenuButton.pressed.connect(_on_main_menu_pressed)
	%ExitButton.pressed.connect(_on_exit_pressed)
	%BackButton.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_unpause()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
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
	settings_panel.show()


func _on_main_menu_pressed() -> void:
	_unpause()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	settings_panel.hide()
	main_buttons.show()


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
