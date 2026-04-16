extends PanelContainer

signal back_pressed

@onready var volume_slider: HSlider = %VolumeSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var env_slider: HSlider = %EnvSlider
@onready var bg_slider: HSlider = %BGSlider
@onready var fullscreen_check: CheckButton = %FullscreenCheck


func _ready() -> void:
	%BackButton.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	env_slider.value_changed.connect(_on_env_changed)
	bg_slider.value_changed.connect(_on_bg_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)


func refresh() -> void:
	volume_slider.value = db_to_linear(
		AudioServer.get_bus_volume_db(0)
	)
	sfx_slider.value = db_to_linear(
		AudioServer.get_bus_volume_db(
			AudioServer.get_bus_index("SFX")
		)
	)
	env_slider.value = db_to_linear(
		AudioServer.get_bus_volume_db(
			AudioServer.get_bus_index("Env")
		)
	)
	bg_slider.value = db_to_linear(
		AudioServer.get_bus_volume_db(
			AudioServer.get_bus_index("BG")
		)
	)
	var mode := DisplayServer.window_get_mode()
	var is_fs := (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)
	fullscreen_check.set_pressed_no_signal(is_fs)


func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))


func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"), linear_to_db(value)
	)


func _on_env_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Env"), linear_to_db(value)
	)


func _on_bg_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("BG"), linear_to_db(value)
	)


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
