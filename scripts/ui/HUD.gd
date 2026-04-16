extends Control

@onready var wave_label: Label = $WavePanel/WaveLabel
@onready var countdown_label: Label = $CountdownPanel/CountdownLabel
@onready var hp_bar: ProgressBar = $StatsPanel/VBox/HPRow/HPBar
@onready var hp_label: Label = $StatsPanel/VBox/HPRow/HPLabel
@onready var scales_label: Label = $StatsPanel/VBox/ScalesRow/ScalesLabel
@onready var magic_label: Label = $StatsPanel/VBox/MagicRow/MagicLabel
@onready var magic_message_label: Label = $MagicMessage
@onready var magic_duration_label: Label = $MagicTimer


var magic_message_time_left: float = 0.0
var magic_effect_time_left: float = 0.0


func _ready() -> void:
	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.scales_changed.connect(_on_scales_changed)
	GameManager.magic_cooldown_changed.connect(_on_magic_cooldown_changed)
	GameManager.magic_burst_casted.connect(_on_magic_burst_casted)
	hp_bar.max_value = GameManager.max_hp
	_on_hp_changed(GameManager.hp)
	_on_scales_changed(GameManager.scales)
	_on_magic_cooldown_changed(GameManager.get_magic_cooldown_left())
	if magic_message_label:
		magic_message_label.visible = false
	if magic_duration_label:
		magic_duration_label.visible = false


func _process(delta: float) -> void:
	if magic_message_time_left > 0.0:
		magic_message_time_left -= delta
		if magic_message_time_left <= 0.0:
			magic_message_time_left = 0.0
			if magic_message_label:
				magic_message_label.visible = false

	if magic_effect_time_left > 0.0:
		magic_effect_time_left -= delta
		if magic_effect_time_left < 0.0:
			magic_effect_time_left = 0.0
		_update_magic_duration_label()
	elif magic_duration_label != null and magic_duration_label.visible:
		magic_duration_label.visible = false
	_update_hud()


func _on_hp_changed(new_hp: int) -> void:
	hp_bar.value = new_hp
	hp_label.text = str(new_hp)
	if new_hp > GameManager.max_hp * 0.5:
		hp_bar.modulate = Color(0.3, 0.9, 0.4)
	elif new_hp > GameManager.max_hp * 0.25:
		hp_bar.modulate = Color(0.9, 0.8, 0.2)
	else:
		hp_bar.modulate = Color(0.9, 0.2, 0.2)


func _on_scales_changed(new_scales: int) -> void:
	scales_label.text = str(new_scales)
	_update_magic_label()


func _on_magic_cooldown_changed(_time_left: float) -> void:
	_update_magic_label()


func _on_magic_burst_casted(_damage: float, _slow_multiplier: float, _slow_duration: float) -> void:
	if magic_message_label == null:
		return
	magic_message_label.text = "Wrogowie osłabieni"
	magic_message_label.visible = true
	magic_message_time_left = 3.0
	magic_effect_time_left = _slow_duration
	_update_magic_duration_label()


func _update_magic_label() -> void:
	if magic_label == null:
		return

	var cd_left := GameManager.get_magic_cooldown_left()
	var cd_total := GameManager.magic_cooldown
	if cd_left > 0.0:
		magic_label.text = "Q Magia (%d): CD %.1f/%.1fs" % [GameManager.magic_cost, cd_left, cd_total]
		magic_label.modulate = Color(0.7, 0.7, 0.9, 1.0)
	elif GameManager.can_afford(GameManager.magic_cost):
		magic_label.text = "Q Magia (%d): GOTOWA | CD %.1fs" % [GameManager.magic_cost, cd_total]
		magic_label.modulate = Color(0.7, 1.0, 0.85, 1.0)
	else:
		magic_label.text = "Q Magia (%d): BRAK LUSEK | CD %.1fs" % [GameManager.magic_cost, cd_total]
		magic_label.modulate = Color(1.0, 0.7, 0.7, 1.0)
func _update_magic_duration_label() -> void:
	if magic_duration_label == null:
		return
	if magic_effect_time_left <= 0.0:
		magic_duration_label.visible = false
		return

	magic_duration_label.visible = true
	magic_duration_label.text = "Magia: %.1fs" % [magic_effect_time_left]


func _update_hud() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var ec := scene_root.find_child(
		"EnemyController", true, false
	) as EnemyController
	if ec == null:
		return

	if ec.waveDefs:
		var total: int = ec.waveDefs.waves.size()
		wave_label.text = "Fala: %d / %d" % [ec.wave_no + 1, total + 1] 
	else:
		wave_label.text = "Fala: %d" % [ec.wave_no + 1]

	if ec.state and ec.state.current_state:
		var st = ec.state.current_state
		if st is PreparationState:
			countdown_label.text = "Kliknij Start!"
		elif st is WaitingForWaveState:
			var t := ceili(st.timer)
			countdown_label.text = "Nastepna fala za: %d" % t
		elif st is SpawningState:
			countdown_label.text = "Fala trwa!"
		else:
			countdown_label.text = ""
	else:
		countdown_label.text = ""
