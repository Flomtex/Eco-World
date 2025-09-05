extends Node
class_name CreatureMover

## Handles creature movement, collision avoidance, and ground snapping.
## Provides a clean interface for movement commands from AI systems.

@export_group("Movement")
@export var move_speed: float = 2.8
@export var turn_speed: float = 4.0

@export_group("Collision Avoidance")
@export var lookahead_distance: float = 0.75
@export var avoidance_samples: int = 16

@export_group("Randomization")
@export var movement_seed: int = -1

# Internal state
var current_heading: Vector3 = Vector3.FORWARD
var creature: Node3D
var terrain: TerrainMap
var rng: RandomNumberGenerator

func _ready() -> void:
	_initialize_dependencies()
	_setup_random_generator()

func _initialize_dependencies() -> void:
	creature = get_parent() as Node3D
	terrain = get_tree().get_first_node_in_group("terrain") as TerrainMap
	
	if not creature:
		push_error("CreatureMover: Parent must be a Node3D")
	if not terrain:
		push_error("CreatureMover: TerrainMap not found in 'terrain' group")

func _setup_random_generator() -> void:
	rng = RandomNumberGenerator.new()
	if movement_seed >= 0:
		rng.seed = movement_seed
	else:
		rng.randomize()

## Initialize creature with random heading
func setup_initial_heading() -> void:
	var random_yaw = rng.randf_range(0.0, TAU)
	current_heading = Vector3(sin(random_yaw), 0.0, cos(random_yaw)).normalized()

## Snap creature to nearest walkable ground cell if currently on unwalkable terrain
func snap_to_ground_if_needed() -> void:
	if not terrain or not creature:
		return
		
	var current_cell = terrain.world_to_ground_cell(creature.global_transform.origin)
	
	if terrain.is_walkable_cell(current_cell):
		return  # Already on walkable terrain
	
	# Search nearby cells for walkable terrain
	var offset_candidates = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
		Vector3i(1, 0, 1), Vector3i(1, 0, -1),
		Vector3i(-1, 0, 1), Vector3i(-1, 0, -1)
	]
	
	for offset in offset_candidates:
		var test_cell = Vector3i(
			current_cell.x + offset.x,
			current_cell.y,
			current_cell.z + offset.z
		)
		
		if terrain.is_walkable_cell(test_cell):
			var snap_position = terrain.cell_to_world(test_cell)
			creature.global_transform.origin.x = snap_position.x
			creature.global_transform.origin.z = snap_position.z
			break

## Execute movement step with desired heading
func step_movement(desired_heading: Vector3, should_move: bool, delta: float) -> void:
	if not creature or not terrain:
		return
	
	# Find safe direction to move (with collision avoidance)
	var safe_direction = _calculate_safe_direction(desired_heading)
	
	# Smoothly turn toward safe direction
	current_heading = _rotate_heading_toward(current_heading, safe_direction, delta)
	
	# Update creature visual rotation (Godot forward = -Z)
	var visual_yaw = atan2(current_heading.x, current_heading.z) + PI
	creature.rotation.y = visual_yaw
	
	# Move if requested and safe to do so
	if should_move:
		var movement_vector = current_heading * move_speed * delta
		var next_position = creature.global_transform.origin + movement_vector
		
		if terrain.is_walkable_world(next_position):
			creature.global_transform.origin = next_position

## Get current movement heading
func get_heading() -> Vector3:
	return current_heading

## Calculate a safe movement direction using collision avoidance
func _calculate_safe_direction(preferred_direction: Vector3) -> Vector3:
	if not terrain:
		return preferred_direction
	
	# Test if preferred direction is safe
	if _is_direction_safe(preferred_direction):
		return preferred_direction.normalized()
	
	# Use sampling to find safe alternative direction
	return _find_safe_direction_by_sampling(preferred_direction)

func _is_direction_safe(direction: Vector3) -> bool:
	var test_position = creature.global_transform.origin + direction.normalized() * lookahead_distance
	return terrain.is_walkable_world(test_position)

func _find_safe_direction_by_sampling(preferred_direction: Vector3) -> Vector3:
	var best_direction = Vector3.FORWARD  # Fallback direction
	var best_alignment = -1.0
	
	# Sample directions around preferred direction
	var start_angle = rng.randf_range(0.0, TAU)
	
	for i in range(avoidance_samples):
		var sample_progress = float(i) / float(max(1, avoidance_samples))
		var sample_angle = start_angle + sample_progress * TAU
		
		var sample_direction = Vector3(sin(sample_angle), 0.0, cos(sample_angle))
		
		if _is_direction_safe(sample_direction):
			var alignment = sample_direction.dot(preferred_direction.normalized())
			if alignment > best_alignment:
				best_alignment = alignment
				best_direction = sample_direction
	
	return best_direction

func _rotate_heading_toward(current: Vector3, target: Vector3, delta: float) -> Vector3:
	var current_yaw = atan2(current.x, current.z)
	var target_yaw = atan2(target.x, target.z)
	
	var yaw_difference = _wrap_angle(target_yaw - current_yaw)
	var max_rotation = turn_speed * delta
	
	yaw_difference = clamp(yaw_difference, -max_rotation, max_rotation)
	var new_yaw = current_yaw + yaw_difference
	
	return Vector3(sin(new_yaw), 0.0, cos(new_yaw)).normalized()

func _wrap_angle(angle: float) -> float:
	return fmod(angle + PI, TAU) - PI
