extends TileMapManager

class_name ProceduralTileMapManager

@export var grid_width: int = 26
@export var grid_height: int = 12
@export var path_margin: int = 2
@export var vertical_step_max: int = 2
@export var turn_chance: float = 0.35

const TILE_SOURCE_ID := 1
const BIOME_GRASS := 0
const BIOME_SAND := 1
const BIOME_WATER := 2

const MASK_N := 1
const MASK_E := 2
const MASK_S := 4
const MASK_W := 8

const TILE_SAND := Vector2i(6, 2)
const TILE_WATER_CENTER := Vector2i(1, 1)
const TILE_GRASS_CENTER := Vector2i(4, 1)

const WATER_MASK_TILES := {
	15: [Vector2i(1, 1)], # N E S W
	14: [Vector2i(1, 0)], # E S W
	13: [Vector2i(2, 1)], # N S W
	11: [Vector2i(1, 2)], # N E W
	7: [Vector2i(0, 1)], # N E S
	12: [Vector2i(2, 0)], # S W
	9: [Vector2i(2, 2)], # N W
	6: [Vector2i(0, 0)], # E S
	3: [Vector2i(0, 2)] # N E
}

const GRASS_MASK_TILES := {
	15: [Vector2i(4, 1), Vector2i(3, 3)],
	14: [Vector2i(3, 4)],
	13: [Vector2i(5, 3)],
	11: [Vector2i(2, 4)],
	7: [Vector2i(4, 3)],
	12: [Vector2i(6, 3)],
	9: [Vector2i(1, 4)],
	6: [Vector2i(7, 3)],
	3: [Vector2i(0, 4)]
}

const ROAD_MASK_TILES := {
	1: [Vector2i(5, 1)], # end (N)
	2: [Vector2i(4, 2), Vector2i(4, 0)], # end (E)
	4: [Vector2i(5, 1)], # end (S)
	8: [Vector2i(4, 2), Vector2i(4, 0)], # end (W)
	3: [Vector2i(3, 2)], # N+E
	6: [Vector2i(3, 0)], # E+S
	12: [Vector2i(5, 0)], # S+W
	9: [Vector2i(5, 2), Vector2i(1, 3)], # N+W
	5: [Vector2i(5, 1), Vector2i(3, 1), Vector2i(4, 2)], # N+S
	10: [Vector2i(4, 2), Vector2i(4, 0)] # E+W
}

var _rng := RandomNumberGenerator.new()
var _ordered_path: Array[Vector2i] = []


func _ready() -> void:
	position = Vector2.ZERO
	_rng.randomize()
	_generate_map()
	_setup_pathfinding()
	_reposition_spawn_and_base()


func _generate_map() -> void:
	road_cells.clear()
	platform_cells.clear()
	towers.clear()
	_ordered_path.clear()
	clear()

	var map_size := _get_map_dimensions()
	var width := map_size.x
	var height := map_size.y

	var min_y := mini(path_margin, height - 2)
	var max_y := maxi(min_y, height - path_margin - 1)
	_ordered_path = _build_road_path(width, min_y, max_y)

	var road_set := _to_cell_set(_ordered_path)
	var biomes := _generate_biomes(width, height, road_set)

	for x in range(width):
		for row in range(height):
			var cell := Vector2i(x, row)
			if road_set.has(cell):
				continue
			var biome: int = biomes[row][x]
			var atlas := _pick_terrain_tile(Vector2i(x, row), biomes, biome)
			platform_cells.append(cell)
			set_cell(cell, TILE_SOURCE_ID, atlas)

	for cell in _ordered_path:
		var road_mask := _neighbor_mask(cell, road_set)
		var road_tile := _pick_masked_tile(road_mask, ROAD_MASK_TILES, TILE_SAND)
		set_cell(cell, TILE_SOURCE_ID, road_tile)
		road_cells.append(cell)


func _build_road_path(width: int, min_y: int, max_y: int) -> Array[Vector2i]:
	var y := _rng.randi_range(min_y, max_y)
	var path: Array[Vector2i] = [Vector2i(0, y)]
	for x in range(1, width):
		if _rng.randf() < turn_chance and x < width - 1:
			var target_y := clampi(
				y + _rng.randi_range(-vertical_step_max, vertical_step_max),
				min_y,
				max_y
			)
			while y != target_y:
				y += signi(target_y - y)
				path.append(Vector2i(x - 1, y))
		path.append(Vector2i(x, y))
	return _dedupe_consecutive(path)


func _generate_biomes(width: int, height: int, road_set: Dictionary) -> Array:
	var biomes: Array = []
	for y in range(height):
		var row: Array = []
		row.resize(width)
		for x in range(width):
			row[x] = BIOME_GRASS
		biomes.append(row)

	_apply_sand_blobs(biomes, width, height)
	_apply_water_lakes(biomes, width, height, road_set)
	_smooth_water(biomes, width, height)
	_enforce_supported_water_masks(biomes, width, height)
	_clear_water_near_road(biomes, width, height, road_set)
	_enforce_supported_water_masks(biomes, width, height)
	_apply_shore_sand(biomes, width, height)
	_smooth_land(biomes, width, height, road_set)
	return biomes


func _apply_sand_blobs(biomes: Array, width: int, height: int) -> void:
	var blob_count := maxi(2, int(round(width / 11.0)))
	for _i in range(blob_count):
		var cx := _rng.randi_range(0, width - 1)
		var cy := _rng.randi_range(0, height - 1)
		var rx := _rng.randi_range(3, maxi(3, int(round(width / 5.0))))
		var ry := _rng.randi_range(2, maxi(2, int(round(height / 3.5))))
		_paint_ellipse(biomes, width, height, cx, cy, rx, ry, BIOME_SAND)


func _apply_water_lakes(biomes: Array, width: int, height: int, road_set: Dictionary) -> void:
	var lake_count := clampi(int(round(width / 14.0)), 2, 4)
	var min_radius := 3
	var max_radius_x := maxi(min_radius, int(round(width / 7.0)))
	var max_radius_y := maxi(min_radius, int(round(height / 3.8)))
	var round_radius_cap := mini(max_radius_x, max_radius_y)

	for _i in range(lake_count):
		var placed := false
		for _attempt in range(24):
			var cx := _rng.randi_range(1, width - 2)
			var cy := _rng.randi_range(1, height - 2)
			if _road_distance_is_too_small(Vector2i(cx, cy), road_set, 4):
				continue
			var base_radius := _rng.randi_range(min_radius, round_radius_cap)
			var rx := clampi(base_radius + _rng.randi_range(-1, 1), min_radius, max_radius_x)
			var ry := clampi(base_radius + _rng.randi_range(-1, 1), min_radius, max_radius_y)
			_paint_ellipse(biomes, width, height, cx, cy, rx, ry, BIOME_WATER)
			placed = true
			break
		if not placed:
			var fallback := Vector2i(_rng.randi_range(0, width - 1), _rng.randi_range(0, height - 1))
			_paint_ellipse(biomes, width, height, fallback.x, fallback.y, 3, 3, BIOME_WATER)


func _paint_ellipse(
	biomes: Array,
	width: int,
	height: int,
	center_x: int,
	center_y: int,
	radius_x: int,
	radius_y: int,
	biome: int
) -> void:
	for y in range(maxi(0, center_y - radius_y), mini(height - 1, center_y + radius_y) + 1):
		for x in range(maxi(0, center_x - radius_x), mini(width - 1, center_x + radius_x) + 1):
			var dx := float(x - center_x) / float(maxi(1, radius_x))
			var dy := float(y - center_y) / float(maxi(1, radius_y))
			if dx * dx + dy * dy <= 1.0:
				biomes[y][x] = biome


func _smooth_water(biomes: Array, width: int, height: int) -> void:
	for _i in range(2):
		var next: Array = []
		for y in range(height):
			var row: Array = []
			row.resize(width)
			next.append(row)
		for y in range(height):
			for x in range(width):
				var current: int = biomes[y][x]
				var water_neighbors := _count_neighbors(biomes, width, height, x, y, BIOME_WATER, true)
				if current == BIOME_WATER and water_neighbors < 3:
					next[y][x] = BIOME_SAND
				elif current != BIOME_WATER and water_neighbors >= 5:
					next[y][x] = BIOME_WATER
				else:
					next[y][x] = current
		biomes.assign(next)


func _clear_water_near_road(biomes: Array, width: int, height: int, road_set: Dictionary) -> void:
	for road_cell in road_set.keys():
		var road_pos: Vector2i = road_cell
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var x: int = road_pos.x + dx
				var y: int = road_pos.y + dy
				if x < 0 or y < 0 or x >= width or y >= height:
					continue
				if biomes[y][x] == BIOME_WATER:
					biomes[y][x] = BIOME_SAND


func _enforce_supported_water_masks(biomes: Array, width: int, height: int) -> void:
	for _i in range(3):
		var next := _clone_biomes(biomes, height)
		var changed := false
		for y in range(height):
			for x in range(width):
				if biomes[y][x] != BIOME_WATER:
					continue
				var cell := Vector2i(x, y)
				var mask := _biome_neighbor_mask(cell, biomes, width, height, BIOME_WATER)
				if WATER_MASK_TILES.has(mask):
					continue
				if mask == (MASK_N | MASK_S):
					_set_biome_if_in_bounds(next, x - 1, y, width, height, BIOME_WATER)
					_set_biome_if_in_bounds(next, x + 1, y, width, height, BIOME_WATER)
				elif mask == (MASK_E | MASK_W):
					_set_biome_if_in_bounds(next, x, y - 1, width, height, BIOME_WATER)
					_set_biome_if_in_bounds(next, x, y + 1, width, height, BIOME_WATER)
				else:
					next[y][x] = BIOME_SAND
				changed = true
		biomes.assign(next)
		if not changed:
			return


func _clone_biomes(biomes: Array, height: int) -> Array:
	var clone: Array = []
	for y in range(height):
		var row: Array = biomes[y].duplicate()
		clone.append(row)
	return clone


func _set_biome_if_in_bounds(
	biomes: Array,
	x: int,
	y: int,
	width: int,
	height: int,
	biome: int
) -> void:
	if x < 0 or y < 0 or x >= width or y >= height:
		return
	biomes[y][x] = biome


func _apply_shore_sand(biomes: Array, width: int, height: int) -> void:
	for y in range(height):
		for x in range(width):
			if biomes[y][x] == BIOME_WATER:
				continue
			if _count_neighbors(biomes, width, height, x, y, BIOME_WATER, false) > 0:
				biomes[y][x] = BIOME_SAND


func _smooth_land(biomes: Array, width: int, height: int, road_set: Dictionary) -> void:
	for _i in range(2):
		var next: Array = []
		for y in range(height):
			var row: Array = []
			row.resize(width)
			next.append(row)

		for y in range(height):
			for x in range(width):
				if biomes[y][x] == BIOME_WATER:
					next[y][x] = BIOME_WATER
					continue
				var cell := Vector2i(x, y)
				if road_set.has(cell):
					next[y][x] = BIOME_SAND
					continue
				if _road_distance_is_too_small(cell, road_set, 1):
					next[y][x] = BIOME_SAND
					continue
				if _count_neighbors(biomes, width, height, x, y, BIOME_WATER, false) > 0:
					next[y][x] = BIOME_SAND
					continue

				var sand_neighbors := _count_neighbors(biomes, width, height, x, y, BIOME_SAND, true)
				next[y][x] = BIOME_SAND if sand_neighbors >= 4 else BIOME_GRASS
		biomes.assign(next)


func _count_neighbors(
	biomes: Array,
	width: int,
	height: int,
	x: int,
	y: int,
	target: int,
	include_diagonals: bool
) -> int:
	var total := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			if not include_diagonals and abs(dx) + abs(dy) != 1:
				continue
			var nx := x + dx
			var ny := y + dy
			if nx < 0 or ny < 0 or nx >= width or ny >= height:
				continue
			if biomes[ny][nx] == target:
				total += 1
	return total


func _road_distance_is_too_small(cell: Vector2i, road_set: Dictionary, radius: int) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if road_set.has(cell + Vector2i(dx, dy)):
				return true
	return false


func _pick_terrain_tile(cell: Vector2i, biomes: Array, biome: int) -> Vector2i:
	var width: int = biomes[0].size()
	var height: int = biomes.size()
	match biome:
		BIOME_WATER:
			var water_mask := _biome_neighbor_mask(cell, biomes, width, height, BIOME_WATER)
			return _pick_masked_tile(water_mask, WATER_MASK_TILES, TILE_WATER_CENTER)
		BIOME_GRASS:
			var grass_mask := _biome_neighbor_mask(cell, biomes, width, height, BIOME_GRASS)
			return _pick_masked_tile(grass_mask, GRASS_MASK_TILES, TILE_GRASS_CENTER)
		_:
			return TILE_SAND


func _biome_neighbor_mask(
	cell: Vector2i,
	biomes: Array,
	width: int,
	height: int,
	target_biome: int
) -> int:
	var mask := 0
	if cell.y > 0 and biomes[cell.y - 1][cell.x] == target_biome:
		mask |= MASK_N
	if cell.x < width - 1 and biomes[cell.y][cell.x + 1] == target_biome:
		mask |= MASK_E
	if cell.y < height - 1 and biomes[cell.y + 1][cell.x] == target_biome:
		mask |= MASK_S
	if cell.x > 0 and biomes[cell.y][cell.x - 1] == target_biome:
		mask |= MASK_W
	return mask


func _neighbor_mask(cell: Vector2i, cell_set: Dictionary) -> int:
	var mask := 0
	if cell_set.has(cell + Vector2i(0, -1)):
		mask |= MASK_N
	if cell_set.has(cell + Vector2i(1, 0)):
		mask |= MASK_E
	if cell_set.has(cell + Vector2i(0, 1)):
		mask |= MASK_S
	if cell_set.has(cell + Vector2i(-1, 0)):
		mask |= MASK_W
	return mask


func _pick_masked_tile(mask: int, tiles_by_mask: Dictionary, fallback: Vector2i) -> Vector2i:
	if tiles_by_mask.has(mask):
		var variants: Array = tiles_by_mask[mask]
		return variants[_rng.randi_range(0, variants.size() - 1)]

	var best_key := -1
	var best_mismatch := 99
	var best_overlap := -1
	for key in tiles_by_mask.keys():
		var mismatch := _bit_count(mask ^ int(key))
		var overlap := _bit_count(mask & int(key))
		if mismatch < best_mismatch:
			best_mismatch = mismatch
			best_overlap = overlap
			best_key = int(key)
		elif mismatch == best_mismatch and overlap > best_overlap:
			best_overlap = overlap
			best_key = int(key)

	if best_key == -1:
		return fallback

	var picked: Array = tiles_by_mask[best_key]
	return picked[_rng.randi_range(0, picked.size() - 1)]


func _bit_count(value: int) -> int:
	var n := value
	var count := 0
	while n != 0:
		count += 1
		n &= n - 1
	return count


func _to_cell_set(cells: Array[Vector2i]) -> Dictionary:
	var result: Dictionary = {}
	for cell in cells:
		result[cell] = true
	return result


func _dedupe_consecutive(cells: Array[Vector2i]) -> Array[Vector2i]:
	if cells.is_empty():
		return []
	var result: Array[Vector2i] = [cells[0]]
	for i in range(1, cells.size()):
		if cells[i] != result[result.size() - 1]:
			result.append(cells[i])
	return result


func _reposition_spawn_and_base() -> void:
	if _ordered_path.size() < 2:
		return
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var spawner := scene_root.find_child("Spawner", true, false) as Node2D
	if spawner:
		spawner.global_position = cell_to_global(_ordered_path[0])

	var base := scene_root.find_child("Base", true, false) as Node2D
	if base:
		base.global_position = cell_to_global(_ordered_path[_ordered_path.size() - 1])


func _get_map_dimensions() -> Vector2i:
	var width := maxi(grid_width, 10)
	var height := maxi(grid_height, 8)
	var tile_px := Vector2i(64, 64)
	if tile_set != null:
		tile_px = tile_set.tile_size

	var viewport_size := get_viewport_rect().size
	if tile_px.x > 0 and tile_px.y > 0 and viewport_size.x > 1.0 and viewport_size.y > 1.0:
		width = maxi(width, int(ceili(viewport_size.x / float(tile_px.x))))
		height = maxi(height, int(ceili(viewport_size.y / float(tile_px.y))))

	return Vector2i(width, height)
