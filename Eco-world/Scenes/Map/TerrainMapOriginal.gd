extends GridMap
class_name TerrainMap


enum Tile { ROCK, GRASS, WATER }

# Match these to your MeshLibrary item IDs
@export var ROCK_ID: int  = 0
@export var GRASS_ID: int = 1
@export var WATER_ID: int = 2
@export var rock_item_ids: PackedInt32Array = [0]

var _used_cells := {} # Set[Vector3i]
var _water_cells := {} # Optional
var _ground_y_by_xz := {} # Dict[Vector2i -> int] topmost Y per (x,z)


func _ready() -> void:
	_used_cells.clear()
	_water_cells.clear()
	_ground_y_by_xz.clear()
	for c in get_used_cells():
		_used_cells[c] = true
		var tid := get_cell_item(c)
		if tid == 2:	# WATER id (adjust if yours differ)
			_water_cells[c] = true
		var key := Vector2i(c.x, c.z)
		if not _ground_y_by_xz.has(key) or c.y > int(_ground_y_by_xz[key]):
			_ground_y_by_xz[key] = c.y
	print("[Terrain] used_cells=", _used_cells.size(), " water_cells=", _water_cells.size())

# ---- ID ↔ Tile ----
func id_to_tile(id: int) -> int:
	if id == WATER_ID:
		return Tile.WATER
	elif id == GRASS_ID:
		return Tile.GRASS
	elif id == ROCK_ID:
		return Tile.ROCK
	return Tile.ROCK

func tile_to_id(t: int) -> int:
	match t:
		Tile.WATER:
			return WATER_ID
		Tile.GRASS:
			return GRASS_ID
		_:
			return ROCK_ID

# ---- Queries on cells ----
func get_cell_type(cell: Vector3i) -> int:
	var id := get_cell_item(cell)
	if id == GridMap.INVALID_CELL_ITEM:
		# Treat empty/out-of-bounds as ordinary ground for now
		return Tile.ROCK
	return id_to_tile(id)
	
func is_walkable_cell(cell: Vector3i) -> bool:
	if not is_in_bounds(cell):
		return false
	var tid := get_cell_item(cell)
	# walkable = rock(0) or grass(1); water(2) blocked
	return tid == 0 or tid == 1

func provides_water(cell: Vector3i) -> bool:
	return get_cell_type(cell) == Tile.WATER

# 4-way neighbors on the same Y layer
func neighbors4(cell: Vector3i) -> Array:
	return [
		cell + Vector3i( 1, 0,  0),
		cell + Vector3i(-1, 0,  0),
		cell + Vector3i( 0, 0,  1),
		cell + Vector3i( 0, 0, -1),
	]

# ---- World ↔ Cell ----
func world_to_cell(world: Vector3) -> Vector3i:
	var local: Vector3 = to_local(world)	# GridMap’s map/local ops use local space
	return local_to_map(local)

func cell_to_world(cell: Vector3i) -> Vector3:
	var local: Vector3 = map_to_local(cell)
	return to_global(local)

func is_in_bounds(cell: Vector3i) -> bool:
	return _used_cells.has(cell)

func ground_cell_from_cell(cell: Vector3i) -> Vector3i:
	var key := Vector2i(cell.x, cell.z)
	if _ground_y_by_xz.has(key):
		return Vector3i(cell.x, int(_ground_y_by_xz[key]), cell.z)
	return cell

func world_to_ground_cell(world: Vector3) -> Vector3i:
	var raw := world_to_cell(world)
	return ground_cell_from_cell(raw)

# Convenience: queries at world-space positions
func get_type_at_world(world: Vector3) -> int:
	var cell: Vector3i = world_to_ground_cell(world)
	if not is_in_bounds(cell):
		return -1
	return get_cell_item(cell)



func is_walkable_world(world: Vector3) -> bool:
	var ground := world_to_ground_cell(world)
	return is_walkable_cell(ground)
	
# If this script is on GridMap, `self` is already a GridMap.
# If you ever move it, this keeps calls working.
func _grid() -> GridMap:
	return self as GridMap

func is_rock_cell(cell: Vector3i) -> bool:
	var id := _grid().get_cell_item(cell)
	return id in rock_item_ids

func pick_spawn_cell_near_rock(rng: RandomNumberGenerator, max_tries: int = 200) -> Variant:
	# Returns a Vector3i or null if none found.
	var used := _grid().get_used_cells()
	if used.is_empty():
		return null

	for i in max_tries:
		var c: Vector3i = used[rng.randi_range(0, used.size() - 1)]
		if is_walkable_cell(c) and not is_rock_cell(c):
			for n in neighbors4(c):
				if is_rock_cell(n):
					return c
	return null
