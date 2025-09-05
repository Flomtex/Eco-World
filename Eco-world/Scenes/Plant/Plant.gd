extends Node3D
class_name Plant

signal consumed(plant: Plant)

@export var energy_value: int = 25
@export var y_offset: float = -0.0         # tweak in Inspector until it sits right
@export var debug_snap_on_ready: bool = true
@export var terrain_map_path: NodePath      # MUST point to the node that has world_to_cell()

var _was_consumed: bool = false
var cell: Vector3i

func place_on_cell(c: Vector3i, terrain: GridMap) -> void:
	cell = c
	var wp: Vector3 = terrain.cell_to_world(cell)
	var half_h := terrain.cell_size.y * 0.5
	global_position = wp + Vector3(0, half_h + y_offset, 0)

func _ready() -> void:
	add_to_group("plants")  # Add to plants group for easy discovery
	if not debug_snap_on_ready or terrain_map_path == NodePath():
		return
	var terrain := get_node(terrain_map_path)
	var c: Vector3i = terrain.world_to_cell(global_position)
	place_on_cell(c, terrain)

func consume() -> int:
	if _was_consumed:
		return 0
	_was_consumed = true
	consumed.emit(self)
	queue_free()
	return energy_value
