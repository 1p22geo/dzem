extends PanelContainer

@export var tower_types: Array[TowerType] = []

var _buttons: Dictionary = {}


func _ready() -> void:
	_build_tower_buttons()
	GameManager.tower_selected.connect(_on_tower_selected)
	GameManager.tower_deselected.connect(_on_tower_deselected)
	GameManager.scales_changed.connect(_on_scales_changed)


func _build_tower_buttons() -> void:
	var list: VBoxContainer = %TowerList
	print ("tower types: ", tower_types)
	for tower_type in tower_types:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 100)
		btn.add_theme_font_size_override("font_size", 24)
		btn.text = "%s\n%d łusek" % [tower_type.name, tower_type.cost]
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if tower_type.texture:
			btn.icon = tower_type.texture
			btn.expand_icon = true
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_tower_button_pressed.bind(tower_type))
		btn.disabled = not GameManager.can_afford(tower_type.cost)
		list.add_child(btn)
		_buttons[tower_type] = btn


func _on_tower_button_pressed(tower_type: TowerType) -> void:
	if GameManager.selected_tower == tower_type:
		GameManager.deselect_tower()
	else:
		if GameManager.can_afford(tower_type.cost):
			GameManager.select_tower(tower_type)


func _on_tower_selected(_tower_type: TowerType) -> void:
	for tt in _buttons:
		var btn: Button = _buttons[tt]
		btn.button_pressed = (tt == _tower_type)


func _on_tower_deselected() -> void:
	for tt in _buttons:
		var btn: Button = _buttons[tt]
		btn.button_pressed = false


func _on_scales_changed(_new_scales: int) -> void:
	for tt in _buttons:
		var btn: Button = _buttons[tt]
		btn.disabled = not GameManager.can_afford(tt.cost)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_RIGHT \
		and event.is_pressed():
		if GameManager.selected_tower:
			GameManager.deselect_tower()
			get_viewport().set_input_as_handled()
