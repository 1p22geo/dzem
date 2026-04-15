extends PanelContainer

var current_tower: Node2D = null

@onready var icon: TextureRect = $Margin/VBox/Icon
@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var range_label: Label = $Margin/VBox/RangeLabel
@onready var damage_label: Label = $Margin/VBox/DamageLabel
@onready var sell_btn: Button = $Margin/VBox/SellButton


func _ready() -> void:
	visible = false
	sell_btn.pressed.connect(_on_sell)
	GameManager.placed_tower_selected.connect(_show)
	GameManager.placed_tower_deselected.connect(_hide)


func _show(tower_node: Node2D) -> void:
	current_tower = tower_node
	var tt: TowerType = tower_node.tower
	icon.texture = tt.texture
	name_label.text = tt.name
	range_label.text = "Zasieg: %d" % tt.attackRange
	damage_label.text = "Obrazenia: %d" % int(tt.damage)
	var sell_price := int(tt.cost * 0.7)
	sell_btn.text = "Sprzedaj ($%d)" % sell_price
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
	var tt: TowerType = current_tower.tower
	var sell_price := int(tt.cost * 0.7)
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
