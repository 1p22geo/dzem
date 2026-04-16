extends TileMapLayer
class_name TileMapManager

var road_cells: Array[Vector2i] = []
var platform_cells: Array[Vector2i] = []
var astar: AStarGrid2D
var towers: Dictionary = {}  # Vector2i -> Node2D (Tower)



func _ready() -> void:
	_classify_tiles()
	_setup_pathfinding()
	print("TileMapManager: %d road, %d platform" % [
		road_cells.size(), platform_cells.size()
	])


func _classify_tiles() -> void:
	for cell in get_used_cells():
		var data: TileData = get_cell_tile_data(cell)
		if data == null:
			continue
		var tile_type: String = data.get_custom_data(
			"tile_type"
		).to_lower()
		match tile_type:
			"road", "rode":
				road_cells.append(cell)
			"platform":
				platform_cells.append(cell)


func _setup_pathfinding() -> void:
	if road_cells.is_empty():
		push_warning("TileMapManager: no road cells found")
		return

	var min_cell := road_cells[0]
	var max_cell := road_cells[0]
	for cell in road_cells:
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)

	astar = AStarGrid2D.new()
	astar.region = Rect2i(min_cell, max_cell - min_cell + Vector2i.ONE)
	astar.cell_size = Vector2(tile_set.tile_size)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()

	# Block all cells, then unblock only road
	for x in range(astar.region.position.x, astar.region.end.x):
		for y in range(astar.region.position.y, astar.region.end.y):
			astar.set_point_solid(Vector2i(x, y), true)

	for cell in road_cells:
		astar.set_point_solid(cell, false)


func get_enemy_path(
	from_pos: Vector2, to_pos: Vector2
) -> PackedVector2Array:
	if astar == null:
		return PackedVector2Array()

	var from_cell := _nearest_road_cell(
		local_to_map(to_local(from_pos))
	)
	var to_cell := _nearest_road_cell(
		local_to_map(to_local(to_pos))
	)

	var id_path := astar.get_id_path(from_cell, to_cell)
	var world_path := PackedVector2Array()
	for cell in id_path:
		world_path.append(self.to_global(map_to_local(cell)))
	return world_path


func cell_to_global(cell: Vector2i) -> Vector2:
	return to_global(map_to_local(cell))


func global_to_cell(pos: Vector2) -> Vector2i:
	return local_to_map(to_local(pos))


func _nearest_road_cell(cell: Vector2i) -> Vector2i:
	if road_cells.has(cell):
		return cell
	var nearest := road_cells[0]
	var min_dist := 999999.0
	for rc in road_cells:
		var dist := float((rc - cell).length())
		if dist < min_dist:
			min_dist = dist
			nearest = rc
	return nearest


func is_platform(cell: Vector2i) -> bool:
	return platform_cells.has(cell)


func has_tower(cell: Vector2i) -> bool:
	return towers.has(cell)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.is_pressed():
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	var mouse_local := to_local(get_global_mouse_position())
	var cell := local_to_map(mouse_local)

	# Click on a placed tower → select it
	if has_tower(cell):
		GameManager.select_placed_tower(towers[cell])
		get_viewport().set_input_as_handled()
		return

	# Click elsewhere → deselect placed tower
	if GameManager.selected_placed_tower:
		GameManager.deselect_placed_tower()

	# Place a new tower on platform
	if not GameManager.selected_tower:
		return
	if not is_platform(cell):
		return

	var sel := GameManager.selected_tower
	if GameManager.spend_scales(sel.cost):
		place_tower(cell, sel)
		GameManager.deselect_tower()
		get_viewport().set_input_as_handled()


func place_tower(cell: Vector2i, tower_type: TowerType) -> void:
	if tower_type == null:
		push_warning("TileMapManager: tried to place a null tower type")
		return
	var tower_node := Node2D.new()
	tower_node.set_script(load("res://scripts/tiles/Tower.gd"))

	var sprite := Sprite2D.new()
	sprite.name = "TowerSprite"
	sprite.texture = tower_type.texture
	tower_node.add_child(sprite)

	tower_node.tower = tower_type
	tower_node.global_position = cell_to_global(cell)
	get_tree().current_scene.add_child(tower_node)
	towers[cell] = tower_node
