extends PanelContainer

var current_tower: Node2D = null

@onready var icon: TextureRect = $Margin/VBox/Icon
@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var range_label: Label = $Margin/VBox/RangeLabel
@onready var damage_label: Label = $Margin/VBox/DamageLabel
@onready var capacity_label: Label = $Margin/VBox/CapacityLabel
@onready var empty_nets_btn: Button = $Margin/VBox/EmptyNetsButton
@onready var upgrade_list: VBoxContainer = $Margin/VBox/UpgradeList
@onready var upgrade_label: Label = $Margin/VBox/UpgradeLabel
@onready var upgrade_sep: HSeparator = $Margin/VBox/UpgradeSep
@onready var sell_btn: Button = $Margin/VBox/SellButton


func _ready() -> void:
	visible = false
	sell_btn.pressed.connect(_on_sell)
	empty_nets_btn.pressed.connect(_on_empty_nets)
	GameManager.placed_tower_selected.connect(_show)
	GameManager.placed_tower_deselected.connect(_hide)
	GameManager.scales_changed.connect(_on_scales_changed)


func _on_empty_nets() -> void:
	if current_tower and current_tower.has_method("empty_nets"):
		current_tower.empty_nets()


func _on_scales_changed(_new_scales: int) -> void:
	if not visible or current_tower == null:
		return
	_update_upgrade_buttons()


func _update_upgrade_buttons() -> void:
	for child in upgrade_list.get_children():
		if child is Button:
			var upg: TowerUpgrade = child.get_meta("upgrade")
			if upg:
				child.disabled = not GameManager.can_afford(upg.cost)


func _show(tower_node: Tower) -> void:
	current_tower = tower_node
	var tt: TowerType = tower_node.tower
	icon.texture = tt.texture
	name_label.text = tt.name
	
	var current_range := tt.attackRange
	var current_damage := tt.damage
	if tower_node.has_method("get_range"):
		current_range = tower_node.get_range()
	if tower_node.has_method("get_damage"):
		current_damage = tower_node.get_damage()
		
	range_label.text = "Zasieg: %d" % int(current_range)
	damage_label.text = "Obrazenia: %d" % int(current_damage)
	
	if tower_node.has_method("get_capacity"):
		var cap := tower_node.get_capacity()
		var cur := tower_node.current_capacity
		capacity_label.text = "Pojemność: %d/%d" % [cur, cap]
		capacity_label.visible = true
		empty_nets_btn.visible = true
		empty_nets_btn.disabled = (cur == 0)
	else:
		capacity_label.visible = false
		empty_nets_btn.visible = false
	
	var sell_price := int(tt.cost * 0.7)
	if tower_node.has_method("get_sell_price"):
		sell_price = tower_node.get_sell_price()
	sell_btn.text = "Sprzedaj ($%d)" % sell_price
	
	# Clear upgrades
	for child in upgrade_list.get_children():
		child.queue_free()
	
	var available_upgrades := 0
	for upg in tt.upgrades:
		if tower_node.is_upgrade_available(upg):
			var btn := Button.new()
			btn.text = "%s ($%d)" % [upg.name, upg.cost]
			btn.tooltip_text = upg.description
			btn.set_meta("upgrade", upg)
			btn.disabled = not GameManager.can_afford(upg.cost)
			btn.pressed.connect(func(): tower_node.apply_upgrade(upg))
			upgrade_list.add_child(btn)
			available_upgrades += 1
		elif tower_node.applied_upgrades.has(upg):
			var lbl := Label.new()
			lbl.text = "%s (Zakupiono)" % upg.name
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			upgrade_list.add_child(lbl)
	
	upgrade_label.visible = (tt.upgrades.size() > 0)
	upgrade_sep.visible = (tt.upgrades.size() > 0)
	
	visible = true


func _hide() -> void:
	current_tower = null
	visible = false


func _process(_delta: float) -> void:
	if not visible or current_tower == null:
		return
	if not is_instance_valid(current_tower):
		visible = false
		return
	_update_position()


func _update_position() -> void:
	var vp := get_viewport()
	var canvas_xform := vp.get_canvas_transform()
	var screen_pos: Vector2 = canvas_xform * current_tower.global_position
	position = screen_pos + Vector2(50, -size.y / 2)
	var vp_size := vp.get_visible_rect().size
	position.x = clampf(
		position.x, 0, vp_size.x - size.x
	)
	position.y = clampf(
		position.y, 0, vp_size.y - size.y
	)


func _on_sell() -> void:
	if current_tower == null:
		return
	var sell_price := 0
	if current_tower.has_method("get_sell_price"):
		sell_price = current_tower.get_sell_price()
	else:
		sell_price = int(current_tower.tower.cost * 0.7)
		
	GameManager.add_scales(sell_price)
	var scene_root := get_tree().current_scene
	var tile_map := scene_root.find_child(
		"TileMapLayer", true, false
	) as TileMapManager
	if tile_map:
		var cell := tile_map.global_to_cell(
			current_tower.global_position
		)
		tile_map.towers.erase(cell)
	current_tower.queue_free()
	GameManager.deselect_placed_tower()
