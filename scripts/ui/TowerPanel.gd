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
		var current_cost = GameManager.get_tower_cost(tower_type)
		btn.text = "%s\n%d łusek" % [tower_type.name, current_cost]
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if tower_type.texture:
			var atlas = AtlasTexture.new()
			atlas.atlas = tower_type.texture
			var frame_width = tower_type.texture.get_width() / 7
			atlas.region = Rect2(0, 0, frame_width, tower_type.texture.get_height())
			btn.icon = atlas
			btn.expand_icon = true
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_tower_button_pressed.bind(tower_type))
		btn.disabled = not GameManager.can_afford(current_cost)
		list.add_child(btn)
		_buttons[tower_type] = btn


func _on_tower_button_pressed(tower_type: TowerType) -> void:
	if GameManager.selected_tower == tower_type:
		GameManager.deselect_tower()
	else:
		var current_cost = GameManager.get_tower_cost(tower_type)
		if GameManager.can_afford(current_cost):
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
		var current_cost = GameManager.get_tower_cost(tt)
		btn.text = "%s\n%d łusek" % [tt.name, current_cost]
		btn.disabled = not GameManager.can_afford(current_cost)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_RIGHT \
		and event.is_pressed():
		if GameManager.selected_tower:
			GameManager.deselect_tower()
			get_viewport().set_input_as_handled()
