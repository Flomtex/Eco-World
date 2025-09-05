extends GridMap
class_name SimplifiedTerrainMap

enum Tile { ROCK, GRASS, WATER }

@export var ROCK_ID: int = 0
@export var GRASS_ID: int = 1
@export var WATER_ID: int = 2

var _used_cells := {}  # Cache for performance

func _ready() -> void:
	_used_cells.clear()
	for cell in get_used_cells():
		_used_cells[cell] = true
	print("[Terrain] Cached ", _used_cells.size(), " cells")

# Core coordinate conversion
func world_to_cell(world: Vector3) -> Vector3i:
	var local: Vector3 = to_local(world)
	return local_to_map(local)

func cell_to_world(cell: Vector3i) -> Vector3:
	var local: Vector3 = map_to_local(cell)
	return to_global(local)

# Essential queries
func is_walkable_world(world: Vector3) -> bool:
	var cell = world_to_cell(world)
	return is_walkable_cell(cell)

func is_walkable_cell(cell: Vector3i) -> bool:
	if not _used_cells.has(cell):
		return false
	var tile_id = get_cell_item(cell)
	return tile_id != WATER_ID  # Everything except water is walkable

# Simple ground positioning (flatten to terrain level)
func world_to_ground_cell(world: Vector3) -> Vector3i:
	var cell = world_to_cell(world)
	# For simplicity, just use the cell as-is
	# Could be enhanced later with height finding if needed
	return cell

# Simple spawning support
func get_random_walkable_cell(rng: RandomNumberGenerator) -> Vector3i:
	var used = get_used_cells()
	var attempts = 100
	while attempts > 0:
		var cell = used[rng.randi_range(0, used.size() - 1)]
		if is_walkable_cell(cell):
			return cell
		attempts -= 1
	return Vector3i.ZERO  # Fallback

# Keep compatibility with existing plant spawning
func pick_spawn_cell_near_rock(rng: RandomNumberGenerator, max_tries: int = 50) -> Variant:
	return get_random_walkable_cell(rng)