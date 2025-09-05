extends Node3D
class_name EcoMap3D

## Clean map controller that initializes and provides basic terrain statistics.
## Serves as the main container for the terrain system.

@onready var terrain_map: TerrainMap = $GridMap

func _ready() -> void:
	_initialize_terrain_system()
	_display_terrain_statistics()

func _initialize_terrain_system() -> void:
	if not terrain_map:
		push_error("EcoMap3D: TerrainMap (GridMap) not found as child")
		return
	
	# Terrain map will initialize itself, but we can validate it here
	if not terrain_map.is_in_group("terrain"):
		terrain_map.add_to_group("terrain")

func _display_terrain_statistics() -> void:
	if not terrain_map:
		return
	
	var water_count = 0
	var walkable_count = 0
	
	for cell in terrain_map.get_used_cells():
		var cell_type = terrain_map.get_cell_type(cell)
		
		if cell_type == TerrainMap.TileType.WATER:
			water_count += 1
		else:
			walkable_count += 1
	
	print("[EcoMap3D] Terrain initialized - walkable: %d, water: %d" % [walkable_count, water_count])
	
	# Example cell query for validation
	var test_cell = Vector3i(0, 0, 0)
	var test_type = terrain_map.get_cell_type(test_cell)
	var is_walkable = terrain_map.is_walkable_cell(test_cell)
	
	print("[EcoMap3D] Cell (0,0,0) - type: %d, walkable: %s" % [test_type, is_walkable])

## Get the terrain map reference (useful for external systems)
func get_terrain_map() -> TerrainMap:
	return terrain_map

## Rebuild terrain caches (useful after runtime terrain modifications)
func refresh_terrain() -> void:
	if terrain_map:
		terrain_map._build_terrain_cache()
		_display_terrain_statistics()
