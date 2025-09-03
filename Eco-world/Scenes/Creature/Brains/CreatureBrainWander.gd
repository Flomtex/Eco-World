extends Node

class_name CreatureBrainWander

signal state_changed(state: int)
const GridPath = preload("res://Scenes/Creature/GridPath.gd")

@onready var sensor: Area3D = (get_node(sense_area_path) as Area3D) if sense_area_path != NodePath() else null
@onready var terrain: TerrainMap = get_tree().get_first_node_in_group("terrain") as TerrainMap

@export var walk_time_range: Vector2 = Vector2(1.3, 3.2)
@export var idle_time_range: Vector2 = Vector2(0.6, 1.8)
@export var turn_time_range: Vector2 = Vector2(0.25, 0.6)
@export var turn_in_place_rate: float = 90.0 * PI / 180.0
@export var jitter_deg: float = 12.0
@export var jitter_interval_range: Vector2 = Vector2(0.8, 2.0)
@export var rng_seed: int = -1


# Sensor hook (points to Creature/SenseArea). Kept generic to avoid custom type errors.
@export_node_path("Area3D") var sense_area_path: NodePath
@export var eat_on_adjacent_cell: bool = true

@export var replan_cooldown: float = 0.3
@export var debug_draw_path: bool = false

var _path: Array[Vector3i] = []
var _last_goal: Vector3i = Vector3i(2147483647, 2147483647, 2147483647)
var _replan_timer: float = 0.0

var _debug_mesh: MeshInstance3D = null

var state: int = MoveState.WALK
var state_time_left: float = 0.0
var turn_dir: float = 1.0
var jitter_time_left: float = 0.0
var rng := RandomNumberGenerator.new()


enum MoveState { WALK, IDLE, TURN }

func _ready() -> void:
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

	# NEW: show whether the sensor is hooked up
	print("[Brain] ready: sense_area_path=", sense_area_path)
	print("[Brain] sensor=", sensor, " has_method=", sensor != null and sensor.has_method("get_visible_target"))


func start() -> void:
	_set_state(MoveState.WALK)
	_reset_jitter_timer()

# Returns {"desired_heading": Vector3, "do_move": bool}
func update(delta: float, current_heading: Vector3) -> Dictionary:
	var h: Vector3 = current_heading

	# --- Eyesight: if a plant is visible, pathfind toward it ---
	if sensor != null:
		var me: Node3D = get_parent() as Node3D
		if me != null and sensor.has_method("get_visible_target"):
			var target: Plant = sensor.call("get_visible_target", me) as Plant
			# Clear path if no target
			if target == null:
				_path.clear()
				_last_goal = Vector3i(2147483647, 2147483647, 2147483647)
			else:
				# Eat when same or adjacent cell (4-neighbour)
				if eat_on_adjacent_cell and terrain != null:
					var my_cell: Vector3i = terrain.world_to_ground_cell(me.global_transform.origin)
					var plant_cell: Vector3i = target.cell
					var neigh := terrain.neighbors4(my_cell)
					if my_cell == plant_cell or neigh.has(plant_cell):
						var gained: int = target.consume()
						print("[Brain] EAT +", gained)
						_path.clear()
						return {"desired_heading": h, "do_move": false}

				# Path plan / reuse
				if terrain != null:
					var start_cell: Vector3i = terrain.world_to_ground_cell(me.global_transform.origin)
					var goal_cell: Vector3i = target.cell
					_replan_timer = maxf(_replan_timer - delta, 0.0)
					if _path.is_empty() or goal_cell != _last_goal or _replan_timer <= 0.0:
						_path = GridPath.plan(start_cell, goal_cell, terrain)
						_last_goal = goal_cell
						_replan_timer = replan_cooldown
						if debug_draw_path:
							_draw_path(_cells_to_world(_path))
						print("[Path] planned ", _path.size(), " steps from ", start_cell, " to ", goal_cell)

					# Follow path
					if _path.size() > 0:
						# Drop waypoint if we're already on it
						if _path[0] == start_cell:
							_path.remove_at(0)
							if debug_draw_path:
								_draw_path(_cells_to_world(_path))
						if _path.size() > 0:
							var next_cell: Vector3i = _path[0]
							var next_wp: Vector3 = terrain.cell_to_world(next_cell)
							var to: Vector3 = next_wp - me.global_transform.origin
							to.y = 0.0
							if to.length_squared() > 0.0001:
								h = to.normalized()
								return {"desired_heading": h, "do_move": true}


	# --- Wander as before ---
	state_time_left -= delta

	match state:
		MoveState.IDLE:
			if state_time_left <= 0.0:
				_set_state(MoveState.WALK if rng.randf() < 0.6 else MoveState.TURN)
			return {"desired_heading": h, "do_move": false}

		MoveState.TURN:
			var yaw: float = atan2(h.x, h.z)
			yaw += turn_dir * turn_in_place_rate * delta
			h = Vector3(sin(yaw), 0.0, cos(yaw)).normalized()
			if state_time_left <= 0.0:
				_set_state(MoveState.WALK)
			return {"desired_heading": h, "do_move": false}

		MoveState.WALK:
			jitter_time_left -= delta
			if jitter_time_left <= 0.0:
				var jitter: float = deg_to_rad(rng.randf_range(-jitter_deg, jitter_deg))
				var yaw2: float = atan2(h.x, h.z) + jitter
				h = Vector3(sin(yaw2), 0.0, cos(yaw2)).normalized()
				_reset_jitter_timer()
			if state_time_left <= 0.0:
				_set_state(MoveState.IDLE if rng.randf() < 0.5 else MoveState.TURN)
			return {"desired_heading": h, "do_move": true}

	return {"desired_heading": h, "do_move": true}

func _set_state(s: int) -> void:
	state = s
	emit_signal("state_changed", state)
	match state:
		MoveState.WALK:
			state_time_left = rng.randf_range(walk_time_range.x, walk_time_range.y)
			print("[Brain] → WALK for ", state_time_left, "s")
		MoveState.IDLE:
			state_time_left = rng.randf_range(idle_time_range.x, idle_time_range.y)
			print("[Brain] → IDLE for ", state_time_left, "s")
		MoveState.TURN:
			state_time_left = rng.randf_range(turn_time_range.x, turn_time_range.y)
			turn_dir = -1.0 if rng.randf() < 0.5 else 1.0
			var tag := "L" if turn_dir < 0.0 else "R"
			print("[Brain] → TURN(", tag, ") for ", state_time_left, "s")

func _reset_jitter_timer() -> void:
	jitter_time_left = rng.randf_range(jitter_interval_range.x, jitter_interval_range.y)

func _cells_to_world(cells: Array[Vector3i]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if terrain == null:
		return out
	for c in cells:
		var p := terrain.cell_to_world(c)
		out.append(p + Vector3(0, 0.05, 0)) # lift a hair to avoid z-fight
	return out
	
func _draw_path(points: Array[Vector3]) -> void:
	if not debug_draw_path:
		return
	if _debug_mesh == null:
		_debug_mesh = MeshInstance3D.new()
		_debug_mesh.name = "PathDebug"
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.2, 0.9, 0.2, 1.0)
		_debug_mesh.material_override = mat
		add_child(_debug_mesh)
	var imm := ImmediateMesh.new()
	if points.size() >= 2:
		imm.surface_begin(Mesh.PRIMITIVE_LINES)
		for i in range(points.size() - 1):
			imm.surface_add_vertex(_debug_mesh.to_local(points[i]))
			imm.surface_add_vertex(_debug_mesh.to_local(points[i + 1]))
		imm.surface_end()
	_debug_mesh.mesh = imm
			
