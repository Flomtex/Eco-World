extends Node
class_name CreatureBrain

## Clean, extensible AI brain for creatures using proper state machine architecture.
## Handles wandering behavior, foraging, and pathfinding with clear separation of concerns.

# Movement states for the creature
enum MovementState {
	IDLE,
	WANDER,
	TURN_IN_PLACE,
	SEEK_FOOD,
	CONSUME_FOOD
}

# Exported configuration
@export_group("Wander Behavior")
@export var idle_duration: Vector2 = Vector2(0.6, 1.8)
@export var walk_duration: Vector2 = Vector2(1.3, 3.2)
@export var turn_duration: Vector2 = Vector2(0.25, 0.6)

@export_group("Movement Parameters")
@export var turn_rate_deg_per_sec: float = 90.0
@export var jitter_degrees: float = 12.0
@export var jitter_interval: Vector2 = Vector2(0.8, 2.0)

@export_group("Foraging")
@export_node_path("Area3D") var sense_area_path: NodePath
@export var consume_on_adjacent: bool = true
@export var pathfind_cooldown: float = 0.6

@export_group("Debug")
@export var debug_state_changes: bool = true
@export var debug_pathfinding: bool = false

# Dependencies - resolved in _ready()
var terrain: TerrainMap
var sensor: CreatureSense
var creature: Node3D

# Internal state
var state_machine: StateMachine
var rng: RandomNumberGenerator

# Foraging state
var target_plant: Plant
var navigation_path: Array[Vector3i]
var last_pathfind_goal: Vector3i
var pathfind_timer: float

# Movement state  
var turn_direction: float
var jitter_timer: float
var current_heading: Vector3

# Debug visualization
var path_debug_mesh: MeshInstance3D

func _ready() -> void:
	_initialize_dependencies()
	_setup_random_generator()
	_create_state_machine()

func _initialize_dependencies() -> void:
	terrain = get_tree().get_first_node_in_group("terrain") as TerrainMap
	creature = get_parent() as Node3D
	
	if sense_area_path != NodePath():
		sensor = get_node(sense_area_path) as CreatureSense
	
	if not terrain:
		push_error("CreatureBrain: TerrainMap not found in 'terrain' group")
	if not creature:
		push_error("CreatureBrain: Parent must be a Node3D")

func _setup_random_generator() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()

func _create_state_machine() -> void:
	state_machine = StateMachine.new()
	state_machine.debug_transitions = debug_state_changes
	add_child(state_machine)
	
	# Define states
	var idle_state = state_machine.add_state(MovementState.IDLE, "IDLE")
	idle_state.enter_callback = _enter_idle
	idle_state.update_callback = _update_idle
	
	var wander_state = state_machine.add_state(MovementState.WANDER, "WANDER")
	wander_state.enter_callback = _enter_wander
	wander_state.update_callback = _update_wander
	
	var turn_state = state_machine.add_state(MovementState.TURN_IN_PLACE, "TURN")
	turn_state.enter_callback = _enter_turn
	turn_state.update_callback = _update_turn
	
	var seek_state = state_machine.add_state(MovementState.SEEK_FOOD, "SEEK_FOOD")
	seek_state.enter_callback = _enter_seek_food
	seek_state.update_callback = _update_seek_food
	
	var consume_state = state_machine.add_state(MovementState.CONSUME_FOOD, "CONSUME_FOOD")
	consume_state.enter_callback = _enter_consume_food
	consume_state.update_callback = _update_consume_food

## Main update function called by creature
func update_brain(delta: float, heading: Vector3) -> Dictionary:
	current_heading = heading
	
	# Check for food targets if we have a sensor
	_update_food_detection()
	
	# Update pathfinding timer
	pathfind_timer = max(pathfind_timer - delta, 0.0)
	
	# Update jitter timer for wandering
	jitter_timer = max(jitter_timer - delta, 0.0)
	
	# Return movement command based on current state
	return _get_movement_command()

func _update_food_detection() -> void:
	if not sensor:
		return
		
	# Try to maintain locked target if still in range
	if target_plant and sensor.is_in_range(target_plant):
		_ensure_seeking_food()
		return
		
	# Look for new target in field of view
	var visible_plant = sensor.get_visible_target(creature)
	if visible_plant:
		target_plant = visible_plant
		_ensure_seeking_food()
	else:
		_clear_food_target()

func _ensure_seeking_food() -> void:
	if not state_machine.is_in_state(MovementState.SEEK_FOOD) and not state_machine.is_in_state(MovementState.CONSUME_FOOD):
		state_machine.change_state(MovementState.SEEK_FOOD)

func _clear_food_target() -> void:
	target_plant = null
	navigation_path.clear()
	last_pathfind_goal = Vector3i.MAX
	
	# Return to wandering if we were seeking food
	if state_machine.is_in_state(MovementState.SEEK_FOOD):
		_transition_to_wander_state()

func _get_movement_command() -> Dictionary:
	match state_machine.current_state:
		MovementState.IDLE:
			return {"desired_heading": current_heading, "do_move": false}
		MovementState.TURN_IN_PLACE:
			return {"desired_heading": _calculate_turn_heading(), "do_move": false}
		MovementState.WANDER:
			return {"desired_heading": _calculate_wander_heading(), "do_move": true}
		MovementState.SEEK_FOOD:
			return _calculate_seek_movement()
		MovementState.CONSUME_FOOD:
			return {"desired_heading": current_heading, "do_move": false}
	
	return {"desired_heading": current_heading, "do_move": false}

# =============================================================================
# STATE IMPLEMENTATIONS
# =============================================================================

func _enter_idle() -> void:
	var duration = rng.randf_range(idle_duration.x, idle_duration.y)
	_schedule_state_transition(duration)

func _update_idle(delta: float) -> void:
	if _is_state_time_expired():
		_transition_to_wander_state()

func _enter_wander() -> void:
	var duration = rng.randf_range(walk_duration.x, walk_duration.y)
	_schedule_state_transition(duration)
	_reset_jitter_timer()

func _update_wander(delta: float) -> void:
	if _is_state_time_expired():
		if rng.randf() < 0.5:
			state_machine.change_state(MovementState.IDLE)
		else:
			state_machine.change_state(MovementState.TURN_IN_PLACE)

func _enter_turn() -> void:
	var duration = rng.randf_range(turn_duration.x, turn_duration.y)
	turn_direction = -1.0 if rng.randf() < 0.5 else 1.0
	_schedule_state_transition(duration)

func _update_turn(delta: float) -> void:
	if _is_state_time_expired():
		state_machine.change_state(MovementState.WANDER)

func _enter_seek_food() -> void:
	# No time limit for seeking - continues until target lost or consumed
	pass

func _update_seek_food(delta: float) -> void:
	if not target_plant or not is_instance_valid(target_plant):
		_clear_food_target()
		return
		
	# Check if we can consume the plant (same or adjacent cell)
	if _can_consume_target():
		state_machine.change_state(MovementState.CONSUME_FOOD)
		return
		
	# Update pathfinding if needed
	_update_pathfinding()

func _enter_consume_food() -> void:
	if target_plant and is_instance_valid(target_plant):
		var energy_gained = target_plant.consume()
		if debug_state_changes:
			print("[Brain] Consumed plant for %d energy" % energy_gained)
	
	# Brief pause after consuming
	_schedule_state_transition(0.1)

func _update_consume_food(delta: float) -> void:
	if _is_state_time_expired():
		_clear_food_target()
		_transition_to_wander_state()

# =============================================================================
# MOVEMENT CALCULATIONS  
# =============================================================================

func _calculate_turn_heading() -> Vector3:
	var current_yaw = atan2(current_heading.x, current_heading.z)
	var turn_rate_rad = deg_to_rad(turn_rate_deg_per_sec)
	current_yaw += turn_direction * turn_rate_rad * get_process_delta_time()
	return Vector3(sin(current_yaw), 0.0, cos(current_yaw)).normalized()

func _calculate_wander_heading() -> Vector3:
	if jitter_timer <= 0.0:
		var jitter_rad = deg_to_rad(rng.randf_range(-jitter_degrees, jitter_degrees))
		var current_yaw = atan2(current_heading.x, current_heading.z)
		current_yaw += jitter_rad
		current_heading = Vector3(sin(current_yaw), 0.0, cos(current_yaw)).normalized()
		_reset_jitter_timer()
	
	return current_heading

func _calculate_seek_movement() -> Dictionary:
	if navigation_path.is_empty():
		return {"desired_heading": current_heading, "do_move": true}
	
	var current_cell = terrain.world_to_ground_cell(creature.global_transform.origin)
	
	# Remove waypoint if we've reached it
	if navigation_path[0] == current_cell:
		navigation_path.remove_at(0)
		_update_path_debug()
	
	if navigation_path.is_empty():
		return {"desired_heading": current_heading, "do_move": true}
	
	# Move toward next waypoint
	var next_cell = navigation_path[0]
	var next_world_pos = terrain.cell_to_world(next_cell)
	var direction = (next_world_pos - creature.global_transform.origin)
	direction.y = 0.0
	
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
		return {"desired_heading": direction, "do_move": true}
	
	return {"desired_heading": current_heading, "do_move": true}

# =============================================================================
# PATHFINDING
# =============================================================================

func _update_pathfinding() -> void:
	if not terrain or not target_plant:
		return
		
	var current_cell = terrain.world_to_ground_cell(creature.global_transform.origin)
	var target_cell = target_plant.cell
	
	# Only replan if needed
	var should_replan = (
		navigation_path.is_empty() or
		target_cell != last_pathfind_goal or
		pathfind_timer <= 0.0
	)
	
	if should_replan:
		navigation_path = GridPath.plan(current_cell, target_cell, terrain)
		last_pathfind_goal = target_cell
		pathfind_timer = pathfind_cooldown
		
		if debug_pathfinding:
			print("[Brain] Planned path of %d steps to %s" % [navigation_path.size(), target_cell])
		
		_update_path_debug()

func _can_consume_target() -> bool:
	if not target_plant or not terrain:
		return false
		
	var current_cell = terrain.world_to_ground_cell(creature.global_transform.origin)
	var target_cell = target_plant.cell
	
	if current_cell == target_cell:
		return true
		
	if consume_on_adjacent:
		var neighbors = terrain.neighbors4(current_cell)
		return target_cell in neighbors
	
	return false

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func _transition_to_wander_state() -> void:
	var next_state = MovementState.WANDER if rng.randf() < 0.6 else MovementState.TURN_IN_PLACE
	state_machine.change_state(next_state)

func _schedule_state_transition(duration: float) -> void:
	# Uses state_machine's built-in state timer - we check it in update functions
	pass

func _is_state_time_expired() -> bool:
	return state_machine.get_state_time() >= _get_current_state_duration()

func _get_current_state_duration() -> float:
	match state_machine.current_state:
		MovementState.IDLE:
			return rng.randf_range(idle_duration.x, idle_duration.y)
		MovementState.WANDER:
			return rng.randf_range(walk_duration.x, walk_duration.y)  
		MovementState.TURN_IN_PLACE:
			return rng.randf_range(turn_duration.x, turn_duration.y)
		MovementState.CONSUME_FOOD:
			return 0.1
	return 1.0

func _reset_jitter_timer() -> void:
	jitter_timer = rng.randf_range(jitter_interval.x, jitter_interval.y)

# =============================================================================
# DEBUG VISUALIZATION
# =============================================================================

func _update_path_debug() -> void:
	if not debug_pathfinding:
		return
		
	if not path_debug_mesh:
		_create_debug_mesh()
	
	var world_points: Array[Vector3] = []
	for cell in navigation_path:
		var world_pos = terrain.cell_to_world(cell)
		world_points.append(world_pos + Vector3(0, 0.05, 0))  # Slight elevation
	
	_draw_path_lines(world_points)

func _create_debug_mesh() -> void:
	path_debug_mesh = MeshInstance3D.new()
	path_debug_mesh.name = "PathDebugVisualization"
	
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.GREEN
	path_debug_mesh.material_override = material
	
	add_child(path_debug_mesh)

func _draw_path_lines(points: Array[Vector3]) -> void:
	if not path_debug_mesh or points.size() < 2:
		if path_debug_mesh:
			path_debug_mesh.mesh = null
		return
	
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for i in range(points.size() - 1):
		var local_start = path_debug_mesh.to_local(points[i])
		var local_end = path_debug_mesh.to_local(points[i + 1])
		
		immediate_mesh.surface_add_vertex(local_start)
		immediate_mesh.surface_add_vertex(local_end)
	
	immediate_mesh.surface_end()
	path_debug_mesh.mesh = immediate_mesh