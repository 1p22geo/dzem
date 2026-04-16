extends Control

@onready var main_buttons: VBoxContainer = %MainButtons
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var logo_area: Control = %LogoArea
@onready var fish_sprite: TextureRect = %FishSprite
@onready var title_image: TextureRect = %TitleImage
@onready var reveal_sfx: AudioStreamPlayer = %RevealSFX
@onready var menu_music: AudioStreamPlayer = %MenuMusic

var intro_scene := preload("res://scenes/ui/IntroSlideshow.tscn")
var _reveal_phase := -1
var _reveal_timer := 0.0
const TITLE_SCALE_DURATION := 0.6
const FISH_FADE_DURATION := 0.5
const BUTTONS_FADE_DURATION := 0.4


func _ready() -> void:
	%PlayButton.pressed.connect(_on_play_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%ExitButton.pressed.connect(_on_exit_pressed)
	settings_panel.back_pressed.connect(_on_settings_back)

	logo_area.modulate = Color.TRANSPARENT
	logo_area.scale = Vector2(0.3, 0.3)
	logo_area.pivot_offset = logo_area.size / 2.0
	main_buttons.modulate = Color(1, 1, 1, 0)
	fish_sprite.modulate = Color.TRANSPARENT
	%PlayButton.modulate = Color.TRANSPARENT
	%SettingsButton.modulate = Color.TRANSPARENT
	%ExitButton.modulate = Color.TRANSPARENT

	_start_intro()


func _start_intro() -> void:
	var intro := intro_scene.instantiate()
	add_child(intro)
	move_child(intro, get_child_count() - 1)
	intro.intro_finished.connect(_on_intro_finished)


func _on_intro_finished() -> void:
	_reveal_phase = 0
	_reveal_timer = 0.0


func _process(delta: float) -> void:
	if _reveal_phase < 0:
		return

	_reveal_timer += delta

	match _reveal_phase:
		0:
			# Phase 0: brief pause before title slam (0.3s)
			if _reveal_timer >= 0.3:
				_reveal_phase = 1
				_reveal_timer = 0.0
				reveal_sfx.play()

		1:
			# Phase 1: title slams in with scale effect
			var t := clampf(
				_reveal_timer / TITLE_SCALE_DURATION, 0.0, 1.0
			)
			var ease_t := _ease_out_back(t)
			logo_area.scale = Vector2(0.3, 0.3).lerp(
				Vector2.ONE, ease_t
			)
			logo_area.modulate = Color(1, 1, 1, t)
			title_image.modulate = Color.WHITE
			if t >= 1.0:
				_reveal_phase = 2
				_reveal_timer = 0.0

		2:
			# Phase 2: fish fades in behind title
			var t := clampf(
				_reveal_timer / FISH_FADE_DURATION, 0.0, 1.0
			)
			fish_sprite.modulate = Color(1, 1, 1, t)
			if t >= 0.3 and not menu_music.playing:
				menu_music.play()
			if t >= 1.0:
				_reveal_phase = 3
				_reveal_timer = 0.0

		3:
			# Phase 3: buttons fade in
			var t := clampf(
				_reveal_timer / BUTTONS_FADE_DURATION, 0.0, 1.0
			)
			%PlayButton.modulate = Color(1, 1, 1, t)
			%SettingsButton.modulate = Color(
				1, 1, 1, clampf(t - 0.15, 0.0, 1.0) / 0.85
			)
			%ExitButton.modulate = Color(
				1, 1, 1, clampf(t - 0.3, 0.0, 1.0) / 0.7
			)
			main_buttons.modulate = Color.WHITE
			if t >= 1.0:
				_reveal_phase = -1


func _ease_out_back(t: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3) + c1 * pow(t - 1.0, 2)


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
