extends GridMap
class_name TerrainMap

# Match these to your MeshLibrary item IDs
@export var ROCK_ID: int  = 0
@export var GRASS_ID: int = 1
@export var WATER_ID: int = 2

enum Tile { ROCK, GRASS, WATER }

func _ready() -> void:
	assert(mesh_library != null, "Assign your MeshLibrary (EcoTiles.tres) to this GridMap.")

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
	# Rule: water is not walkable; rock/grass are walkable
	return get_cell_type(cell) != Tile.WATER

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
func world_to_cell(world_pos: Vector3) -> Vector3i:
	var local: Vector3 = to_local(world_pos)
	return local_to_map(local)

func cell_to_world(cell: Vector3i) -> Vector3:
	var local: Vector3 = map_to_local(cell)
	return to_global(local)

# Convenience: queries at world-space positions
func get_type_at_world(world_pos: Vector3) -> int:
	return get_cell_type(world_to_cell(world_pos))

func is_walkable_world(world_pos: Vector3) -> bool:
	return is_walkable_cell(world_to_cell(world_pos))
