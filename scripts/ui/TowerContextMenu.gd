extends PanelContainer

var current_tower: Node2D = null

@onready var icon: TextureRect = $Margin/VBox/Icon
@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var range_label: Label = $Margin/VBox/RangeLabel
@onready var damage_label: Label = $Margin/VBox/DamageLabel
@onready var capacity_label: Label = $Margin/VBox/CapacityLabel
@onready var total_damage_label: Label = $Margin/VBox/TotalDamageLabel
@onready var empty_nets_btn: Button = $Margin/VBox/EmptyNetsButton
@onready var upgrade_list: VBoxContainer = $Margin/VBox/UpgradeList
@onready var upgrade_label: Label = $Margin/VBox/UpgradeLabel
@onready var upgrade_sep: HSeparator = $Margin/VBox/UpgradeSep
@onready var sell_btn: Button = $Margin/VBox/SellButton

var targeting_selector: OptionButton
var ability_btn: Button
var evolution_list: VBoxContainer
var evolution_label: Label
var evolution_sep: HSeparator

func _ready() -> void:
	visible = false
	sell_btn.pressed.connect(_on_sell)
	empty_nets_btn.pressed.connect(_on_empty_nets)
	GameManager.placed_tower_selected.connect(_show)
	GameManager.placed_tower_deselected.connect(_hide)
	GameManager.scales_changed.connect(_on_scales_changed)
	
	_setup_targeting_ui()
	_setup_ability_ui()
	_setup_evolution_ui()

func _setup_targeting_ui() -> void:
	var label = Label.new()
	label.text = "Celowanie:"
	label.add_theme_font_size_override("font_size", 18)
	$Margin/VBox.add_child(label)
	# Move after damage label
	var damage_idx = damage_label.get_index()
	$Margin/VBox.move_child(label, damage_idx + 1)
	
	targeting_selector = OptionButton.new()
	targeting_selector.add_item("Pierwszy", Tower.TargetingMode.FIRST)
	targeting_selector.add_item("Ostatni", Tower.TargetingMode.LAST)
	targeting_selector.add_item("Najbliższy", Tower.TargetingMode.CLOSEST)
	targeting_selector.add_item("Najsilniejszy", Tower.TargetingMode.STRONGEST)
	targeting_selector.add_item("Najsłabszy", Tower.TargetingMode.WEAKEST)
	targeting_selector.add_item("Losowy", Tower.TargetingMode.RANDOM)
	targeting_selector.item_selected.connect(_on_targeting_selected)
	$Margin/VBox.add_child(targeting_selector)
	$Margin/VBox.move_child(targeting_selector, damage_idx + 2)

func _setup_ability_ui() -> void:
	ability_btn = Button.new()
	ability_btn.text = "Użyj umiejętności"
	ability_btn.add_theme_font_size_override("font_size", 18)
	ability_btn.pressed.connect(_on_ability_pressed)
	$Margin/VBox.add_child(ability_btn)
	# Position before upgrades
	var upg_label_idx = upgrade_label.get_index()
	$Margin/VBox.move_child(ability_btn, upg_label_idx)

func _setup_evolution_ui() -> void:
	evolution_sep = HSeparator.new()
	$Margin/VBox.add_child(evolution_sep)
	
	evolution_label = Label.new()
	evolution_label.text = "Ewolucje:"
	evolution_label.add_theme_font_size_override("font_size", 20)
	$Margin/VBox.add_child(evolution_label)
	
	evolution_list = VBoxContainer.new()
	$Margin/VBox.add_child(evolution_list)

func _on_ability_pressed() -> void:
	if current_tower and current_tower.has_method("use_active_ability"):
		if current_tower.use_active_ability():
			_show(current_tower)

func _on_targeting_selected(index: int) -> void:
	if current_tower and "targeting_mode" in current_tower:
		current_tower.targeting_mode = targeting_selector.get_item_id(index)

func _on_empty_nets() -> void:
	if current_tower and current_tower.has_method("empty_nets"):
		current_tower.empty_nets()


func _on_scales_changed(_new_scales: int) -> void:
	if not visible or current_tower == null:
		return
	_update_upgrade_buttons()
	_update_evolution_buttons()


func _update_upgrade_buttons() -> void:
	for child in upgrade_list.get_children():
		if child is Button:
			var upg: TowerUpgrade = child.get_meta("upgrade")
			if upg:
				child.disabled = not GameManager.can_afford(upg.cost)

func _update_evolution_buttons() -> void:
	for child in evolution_list.get_children():
		if child is Button:
			var et: TowerType = child.get_meta("evolution")
			if et:
				var is_max = current_tower.is_max_upgraded()
				var already_exists = GameManager.is_evolution_on_map(et.evolution_id)
				child.disabled = not GameManager.can_afford(et.cost) or already_exists or not is_max
				
				var btn_text = "Ewolucja: %s ($%d)" % [et.name, et.cost]
				if not is_max:
					btn_text += " (Wymaga ulepszeń)"
				elif already_exists:
					btn_text += " (Max 1)"
				child.text = btn_text


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
	
	if "targeting_mode" in tower_node:
		targeting_selector.selected = -1 # Clear selection first to be safe
		for i in range(targeting_selector.item_count):
			if targeting_selector.get_item_id(i) == tower_node.targeting_mode:
				targeting_selector.selected = i
				break
	
	total_damage_label.text = "Zadano: %d dmg" % int(tower_node.total_damage_dealt)
	
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
	
	# Ability Button
	if tt.has_active_ability:
		ability_btn.visible = true
		ability_btn.text = tt.ability_name
		ability_btn.tooltip_text = tt.ability_description
		
		# Cooldown check
		var last_used = tower_node.get("_ability_last_used_wave")
		var cooldown = tt.ability_cooldown_waves
		var current_wave = GameManager.get_current_wave_index()
		var waves_passed = current_wave - last_used
		
		if waves_passed < cooldown:
			ability_btn.disabled = true
			ability_btn.text = "%s (%d fal)" % [tt.ability_name, cooldown - waves_passed]
		else:
			ability_btn.disabled = false
	else:
		ability_btn.visible = false

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
	
	# Evolutions
	for child in evolution_list.get_children():
		child.queue_free()
		
	if tt.evolutions.is_empty():
		evolution_label.visible = false
		evolution_sep.visible = false
		evolution_list.visible = false
	else:
		evolution_label.visible = true
		evolution_sep.visible = true
		evolution_list.visible = true
		var is_max = tower_node.is_max_upgraded()
		for et in tt.evolutions:
			var btn := Button.new()
			btn.set_meta("evolution", et)
			var already_exists = GameManager.is_evolution_on_map(et.evolution_id)
			btn.disabled = not GameManager.can_afford(et.cost) or already_exists or not is_max
			
			var btn_text = "Ewolucja: %s ($%d)" % [et.name, et.cost]
			if not is_max:
				btn_text += " (Wymaga ulepszeń)"
			elif already_exists:
				btn_text += " (Max 1)"
			btn.text = btn_text
			
			btn.pressed.connect(func(): tower_node.evolve_into(et))
			evolution_list.add_child(btn)
	
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
