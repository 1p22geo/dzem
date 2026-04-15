extends PanelContainer

signal back_pressed

@onready var volume_slider: HSlider = %VolumeSlider
@onready var fullscreen_check: CheckButton = %FullscreenCheck


func _ready() -> void:
	%BackButton.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)


func refresh() -> void:
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	fullscreen_check.button_pressed = (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)


func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
