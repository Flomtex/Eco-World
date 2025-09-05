extends Node3D
class_name Plant

## Clean plant implementation with consumption mechanics and terrain integration.
## Handles placement, energy provision, and consumption lifecycle.

signal consumed(plant: Plant)

@export_group("Properties")
@export var energy_value: int = 25
@export var vertical_offset: float = 0.0

@export_group("Terrain Integration") 
@export var snap_to_terrain_on_ready: bool = true
@export_node_path("TerrainMap") var terrain_map_path: NodePath

# Internal state
var grid_cell: Vector3i
var is_consumed: bool = false

func _ready() -> void:
	if snap_to_terrain_on_ready:
		_snap_to_terrain()

## Place plant on a specific grid cell with proper world positioning
func place_on_cell(cell: Vector3i, terrain: TerrainMap) -> void:
	grid_cell = cell
	
	var world_position = terrain.cell_to_world(cell)
	var cell_half_height = terrain.cell_size.y * 0.5
	
	global_position = world_position + Vector3(0, cell_half_height + vertical_offset, 0)

## Consume this plant and return energy value
func consume() -> int:
	if is_consumed:
		return 0
	
	is_consumed = true
	consumed.emit(self)
	
	# Remove plant from scene
	queue_free()
	
	return energy_value

## Get the grid cell this plant occupies
func get_cell() -> Vector3i:
	return grid_cell

## Legacy property for backward compatibility
@warning_ignore("unused_parameter")
var cell: Vector3i:
	get:
		return grid_cell
	set(value):
		grid_cell = value

## Check if plant has been consumed
func is_plant_consumed() -> bool:
	return is_consumed

func _snap_to_terrain() -> void:
	if terrain_map_path == NodePath():
		return
		
	var terrain = get_node(terrain_map_path) as TerrainMap
	if not terrain:
		push_warning("Plant: TerrainMap not found at path: %s" % terrain_map_path)
		return
	
	var world_cell = terrain.world_to_cell(global_position)
	place_on_cell(world_cell, terrain)
