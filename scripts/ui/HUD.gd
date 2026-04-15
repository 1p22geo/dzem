extends PanelContainer

@onready var hp_bar: ProgressBar = $Margin/HBox/HPSection/HPBar
@onready var hp_label: Label = $Margin/HBox/HPSection/HPLabel
@onready var scales_label: Label = $Margin/HBox/ScalesSection/ScalesLabel
@onready var wave_label: Label = $Margin/HBox/WaveSection/WaveLabel


func _ready() -> void:
	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.scales_changed.connect(_on_scales_changed)
	hp_bar.max_value = GameManager.max_hp
	_on_hp_changed(GameManager.hp)
	_on_scales_changed(GameManager.scales)
	_update_wave()


func _process(_delta: float) -> void:
	_update_wave()


func _on_hp_changed(new_hp: int) -> void:
	hp_bar.value = new_hp
	hp_label.text = "%d / %d" % [new_hp, GameManager.max_hp]
	if new_hp > GameManager.max_hp * 0.5:
		hp_bar.modulate = Color(0.2, 0.9, 0.3)
	elif new_hp > GameManager.max_hp * 0.25:
		hp_bar.modulate = Color(0.9, 0.8, 0.2)
	else:
		hp_bar.modulate = Color(0.9, 0.2, 0.2)


func _on_scales_changed(new_scales: int) -> void:
	scales_label.text = str(new_scales)


func _update_wave() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var ec := scene_root.find_child(
		"EnemyController", true, false
	) as EnemyController
	if ec and ec.waveDefs:
		var total: int = ec.waveDefs.waves.size()
		wave_label.text = "%d / %d" % [ec.wave_no, total]
	elif ec:
		wave_label.text = str(ec.wave_no)
