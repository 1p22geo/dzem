extends Tile

@export var tower: TowerType

var has_tower: bool = false


func _ready() -> void:
	if tower:
		place_tower(tower)


func _process(delta: float) -> void:
	pass


func place_tower(tower_type: TowerType) -> void:
	tower = tower_type
	has_tower = true
	$Tower/Sprite2D.texture = tower.texture
	$Tower.tower = tower


func _input(event) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.is_pressed() or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if has_tower:
		return
	if not GameManager.selected_tower:
		return

	var sprite: Sprite2D = $Ground
	var size = sprite.texture.get_size() * sprite.scale
	var rect = Rect2(global_position - size / 2.0, size)
	var cam = get_viewport().get_camera_2d()
	var mouse_pos = cam.get_global_mouse_position() if cam else get_global_mouse_position()
	if not rect.has_point(mouse_pos):
		return

	var selected = GameManager.selected_tower
	if GameManager.spend_scales(selected.cost):
		place_tower(selected)
		GameManager.deselect_tower()
