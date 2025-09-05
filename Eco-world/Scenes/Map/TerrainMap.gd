extends GridMap
class_name TerrainMap

## Clean terrain management system providing grid-based world queries and pathfinding support.
## Handles coordinate conversions, walkability checks, and spawn location finding.

# Tile type enumeration for clear terrain identification
enum TileType { 
	ROCK, 
	GRASS, 
	WATER 
}

@export_group("Tile Configuration")
@export var rock_tile_id: int = 0
@export var grass_tile_id: int = 1
@export var water_tile_id: int = 2

@export_group("Rock Detection")
@export var rock_item_ids: PackedInt32Array = [0]

# Internal caching for performance
var _cached_used_cells: Dictionary = {}  # Set[Vector3i] -> bool
var _cached_water_cells: Dictionary = {} # Set[Vector3i] -> bool  
var _ground_height_map: Dictionary = {}  # Dict[Vector2i -> int] for top Y per (x,z)

func _ready() -> void:
	_build_terrain_cache()

## Rebuild internal caches after terrain changes
func _build_terrain_cache() -> void:
	_cached_used_cells.clear()
	_cached_water_cells.clear()
	_ground_height_map.clear()
	
	var used_cells = get_used_cells()
	
	for cell in used_cells:
		_cached_used_cells[cell] = true
		
		var tile_id = get_cell_item(cell)
		if tile_id == water_tile_id:
			_cached_water_cells[cell] = true
		
		# Track highest Y coordinate for each (x,z) position
		var xz_key = Vector2i(cell.x, cell.z)
		if not _ground_height_map.has(xz_key) or cell.y > _ground_height_map[xz_key]:
			_ground_height_map[xz_key] = cell.y
	
	print("[TerrainMap] Cache built - cells: %d, water: %d" % [
		_cached_used_cells.size(), 
		_cached_water_cells.size()
	])

# =============================================================================
# COORDINATE CONVERSION SYSTEM
# =============================================================================

## Convert world position to grid cell coordinates
func world_to_cell(world_position: Vector3) -> Vector3i:
	var local_position = to_local(world_position)
	return local_to_map(local_position)

## Convert grid cell to world position
func cell_to_world(cell: Vector3i) -> Vector3:
	var local_position = map_to_local(cell)
	return to_global(local_position)

## Convert any cell to the ground-level cell at the same (x,z) coordinate
func ground_cell_from_cell(cell: Vector3i) -> Vector3i:
	var xz_key = Vector2i(cell.x, cell.z)
	if _ground_height_map.has(xz_key):
		return Vector3i(cell.x, _ground_height_map[xz_key], cell.z)
	return cell

## Convert world position directly to ground-level cell
func world_to_ground_cell(world_position: Vector3) -> Vector3i:
	var cell = world_to_cell(world_position)
	return ground_cell_from_cell(cell)

# =============================================================================
# TERRAIN QUERIES
# =============================================================================

## Check if a cell coordinate is within terrain bounds
func is_in_bounds(cell: Vector3i) -> bool:
	return _cached_used_cells.has(cell)

## Get the tile type at a specific cell
func get_cell_type(cell: Vector3i) -> int:
	var tile_id = get_cell_item(cell)
	return _tile_id_to_type(tile_id)

## Check if a cell is walkable (not water, not out of bounds)
func is_walkable_cell(cell: Vector3i) -> bool:
	if not is_in_bounds(cell):
		return false
	
	var tile_id = get_cell_item(cell)
	# Walkable tiles: rock(0) and grass(1), but not water(2)
	return tile_id == rock_tile_id or tile_id == grass_tile_id

## Check if a world position is on walkable terrain
func is_walkable_world(world_position: Vector3) -> bool:
	var ground_cell = world_to_ground_cell(world_position)
	return is_walkable_cell(ground_cell)

## Check if a cell provides water
func provides_water(cell: Vector3i) -> bool:
	return get_cell_type(cell) == TileType.WATER

## Check if a cell is a rock type
func is_rock_cell(cell: Vector3i) -> bool:
	var tile_id = get_cell_item(cell)
	return tile_id in rock_item_ids

## Get tile type from world position
func get_type_at_world(world_position: Vector3) -> int:
	var cell = world_to_ground_cell(world_position)
	if not is_in_bounds(cell):
		return -1  # Invalid/out of bounds
	return get_cell_item(cell)

# =============================================================================
# NEIGHBOR QUERIES
# =============================================================================

## Get 4-directional neighbors of a cell (same Y level)
func neighbors4(cell: Vector3i) -> Array:
	return [
		cell + Vector3i(1, 0, 0),   # East
		cell + Vector3i(-1, 0, 0),  # West  
		cell + Vector3i(0, 0, 1),   # South
		cell + Vector3i(0, 0, -1),  # North
	]

## Get 8-directional neighbors of a cell (same Y level)
func get_neighbors_8(cell: Vector3i) -> Array[Vector3i]:
	var neighbors: Array[Vector3i] = []
	
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			if dx == 0 and dz == 0:
				continue  # Skip center cell
			neighbors.append(cell + Vector3i(dx, 0, dz))
	
	return neighbors

# =============================================================================
# SPAWN LOCATION FINDING
# =============================================================================

## Find a random walkable cell adjacent to rock (for plant spawning)
func pick_spawn_cell_near_rock(rng: RandomNumberGenerator, max_attempts: int = 200) -> Variant:
	var used_cells = get_used_cells()
	if used_cells.is_empty():
		return null
	
	for attempt in range(max_attempts):
		# Pick random cell from terrain
		var candidate_cell: Vector3i = used_cells[rng.randi_range(0, used_cells.size() - 1)]
		
		# Must be walkable but not rock itself
		if not is_walkable_cell(candidate_cell) or is_rock_cell(candidate_cell):
			continue
		
		# Must be adjacent to at least one rock cell
		for neighbor in neighbors4(candidate_cell):
			if is_rock_cell(neighbor):
				return candidate_cell
	
	return null  # No valid spawn location found

# =============================================================================
# BACKWARD COMPATIBILITY & INTERNAL UTILITIES
# =============================================================================

## Legacy tile ID conversion (for backward compatibility)
func id_to_tile(id: int) -> int:
	return _tile_id_to_type(id)

func tile_to_id(tile_type: int) -> int:
	match tile_type:
		TileType.WATER:
			return water_tile_id
		TileType.GRASS:
			return grass_tile_id
		_:
			return rock_tile_id

func _tile_id_to_type(tile_id: int) -> int:
	match tile_id:
		water_tile_id:
			return TileType.WATER
		grass_tile_id:
			return TileType.GRASS
		rock_tile_id:
			return TileType.ROCK
		GridMap.INVALID_CELL_ITEM:
			return TileType.ROCK  # Treat empty as rock for now
		_:
			return TileType.ROCK  # Default fallback

## For backward compatibility - use TileType enum instead
enum Tile { ROCK, GRASS, WATER }

# Legacy exports for backward compatibility
@export var ROCK_ID: int = 0
@export var GRASS_ID: int = 1  
@export var WATER_ID: int = 2