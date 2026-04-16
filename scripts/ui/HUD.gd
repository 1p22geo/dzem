extends Control

@onready var wave_label: Label = $WavePanel/WaveLabel
@onready var countdown_label: Label = $CountdownPanel/CountdownLabel
@onready var hp_bar: ProgressBar = $StatsPanel/VBox/HPRow/HPBar
@onready var hp_label: Label = $StatsPanel/VBox/HPRow/HPLabel
@onready var scales_label: Label = $StatsPanel/VBox/ScalesRow/ScalesLabel


func _ready() -> void:
	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.scales_changed.connect(_on_scales_changed)
	hp_bar.max_value = GameManager.max_hp
	_on_hp_changed(GameManager.hp)
	_on_scales_changed(GameManager.scales)


func _process(_delta: float) -> void:
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
