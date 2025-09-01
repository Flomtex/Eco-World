extends Node3D

# ---- Tuning ----
const MOVE_SPEED: float = 2.8			# meters/sec (XZ plane)
const TURN_SPEED: float = 4.0			# rad/sec towards chosen dir
const LOOKAHEAD: float = 0.75			# meters ahead to probe
const SAMPLE_DIRECTIONS: int = 16		# radial samples

# Wander feel
const WALK_TIME_RANGE := Vector2(1.3, 3.2)	# seconds
const IDLE_TIME_RANGE := Vector2(0.6, 1.8)
const TURN_TIME_RANGE := Vector2(0.25, 0.6)
const TURN_IN_PLACE_RATE: float = 90.0 * PI / 180.0	# rad/s when in TURN state
const JITTER_DEG: float = 12.0						# small heading nudge while walking
const JITTER_INTERVAL_RANGE := Vector2(0.8, 2.0)	# seconds between nudges

@onready var terrain: Node = get_tree().get_first_node_in_group("terrain")
var heading: Vector3 = Vector3.FORWARD	# XZ-only
var rng := RandomNumberGenerator.new()

# --- Micro-FSM ---
enum MoveState { WALK, IDLE, TURN }
var state: int = MoveState.WALK
var state_time_left: float = 0.0
var turn_dir: float = 1.0					# +1 or -1 during TURN
var jitter_time_left: float = 0.0			# counts down to next tiny nudge

func _ready() -> void:
	rng.randomize()
	# Randomize initial heading a little so multiple creatures don't match
	var yaw0 := rng.randf_range(0.0, TAU)
	heading = Vector3(sin(yaw0), 0.0, cos(yaw0))

	# Snap start to ground layer & make sure it's legal (from earlier fix)
	var start_cell: Vector3i = terrain.world_to_ground_cell(global_transform.origin)
	if not terrain.is_walkable_cell(start_cell):
		print("[Creature] Spawn non-walkable @", start_cell, " — nudging.")
		for off in [
			Vector3i(1,0,0), Vector3i(-1,0,0),
			Vector3i(0,0,1), Vector3i(0,0,-1),
			Vector3i(1,0,1), Vector3i(1,0,-1), Vector3i(-1,0,1), Vector3i(-1,0,-1)
		]:
			var c := Vector3i(start_cell.x + off.x, start_cell.y, start_cell.z + off.z)
			if terrain.is_walkable_cell(c):
				var snap: Vector3 = terrain.cell_to_world(c)
				global_transform.origin.x = snap.x
				global_transform.origin.z = snap.z
				print("[Creature] Snapped to ", c, " => ", snap)
				break

	_set_state(MoveState.WALK)	# start walking
	_reset_jitter_timer()


func _physics_process(delta: float) -> void:
	# 1) Update micro-FSM timers and heading intent
	state_time_left -= delta
	match state:
		MoveState.IDLE:
			# stand still, keep heading (no translation)
			if state_time_left <= 0.0:
				# 60% → WALK, 40% → TURN
				_set_state(MoveState.WALK if rng.randf() < 0.6 else MoveState.TURN)

		MoveState.TURN:
			# rotate in place a bit
			var yaw := atan2(heading.x, heading.z)
			yaw += turn_dir * TURN_IN_PLACE_RATE * delta
			heading = Vector3(sin(yaw), 0.0, cos(yaw)).normalized()
			if state_time_left <= 0.0:
				_set_state(MoveState.WALK)

		MoveState.WALK:
			# occasional tiny heading nudge for natural drift
			jitter_time_left -= delta
			if jitter_time_left <= 0.0:
				# small random yaw delta
				var jitter := deg_to_rad(rng.randf_range(-JITTER_DEG, JITTER_DEG))
				var yaw := atan2(heading.x, heading.z) + jitter
				heading = Vector3(sin(yaw), 0.0, cos(yaw)).normalized()
				_reset_jitter_timer()
			if state_time_left <= 0.0:
				# 50% pause, 50% little turn
				_set_state(MoveState.IDLE if rng.randf() < 0.5 else MoveState.TURN)

	# 2) Choose a walkable direction close to our current heading
	var desired_dir := _pick_walkable_direction(heading)
	if desired_dir == Vector3.ZERO:
		# boxed in—stay put this frame
		return

	# 3) Smoothly steer toward desired_dir (slows edge “snapping”)
	var current_yaw := atan2(heading.x, heading.z)
	var target_yaw := atan2(desired_dir.x, desired_dir.z)
	var new_yaw := _rotate_towards(current_yaw, target_yaw, TURN_SPEED * delta)
	heading = Vector3(sin(new_yaw), 0.0, cos(new_yaw)).normalized()
	var face_yaw := atan2(heading.x, heading.z) + PI
	rotation.y = face_yaw
	
	# 4) Translate only if walking
	if state == MoveState.WALK:
		var step := heading * MOVE_SPEED * delta
		var next_pos := global_transform.origin + step
		if _is_pos_walkable(next_pos):
			global_transform.origin = next_pos
		else:
			# near a boundary; no forced move—steering sampler will adapt next frame
			print("[Creature] Blocked final step: world=", next_pos, " cell=", terrain.world_to_cell(next_pos))

func _set_state(s: int) -> void:
	state = s
	match state:
		MoveState.WALK:
			state_time_left = rng.randf_range(WALK_TIME_RANGE.x, WALK_TIME_RANGE.y)
			print("[Creature] → WALK for ", state_time_left, "s")
		MoveState.IDLE:
			state_time_left = rng.randf_range(IDLE_TIME_RANGE.x, IDLE_TIME_RANGE.y)
			print("[Creature] → IDLE for ", state_time_left, "s")
		MoveState.TURN:
			state_time_left = rng.randf_range(TURN_TIME_RANGE.x, TURN_TIME_RANGE.y)
			turn_dir = -1.0 if rng.randf() < 0.5 else 1.0
			var turn_label := "L" if turn_dir < 0.0 else "R"
			print("[Creature] → TURN(", turn_label, ") for ", state_time_left, "s")

func _reset_jitter_timer() -> void:
	jitter_time_left = rng.randf_range(JITTER_INTERVAL_RANGE.x, JITTER_INTERVAL_RANGE.y)


func _pick_walkable_direction(preferred: Vector3) -> Vector3:
	# try forward first
	var forward_probe := global_transform.origin + preferred.normalized() * LOOKAHEAD
	if _is_pos_walkable(forward_probe):
		return preferred.normalized()

	# radial search — pick valid dir with best alignment to preferred
	var best_dir := Vector3.ZERO
	var best_dot := -1.0
	var start_angle := rng.randf_range(0.0, TAU)
	for i in range(SAMPLE_DIRECTIONS):
		var t := float(i) / float(max(1, SAMPLE_DIRECTIONS))
		var ang := start_angle + t * TAU
		var dir := Vector3(sin(ang), 0.0, cos(ang))
		var probe := global_transform.origin + dir * LOOKAHEAD
		if _is_pos_walkable(probe):
			var d := dir.dot(preferred.normalized())
			if d > best_dot:
				best_dot = d
				best_dir = dir
	if best_dir == Vector3.ZERO:
		var here: Vector3 = terrain.world_to_ground_cell(global_transform.origin)
		print("[Creature] No walkable dir @ world=", global_transform.origin, " cell=", here)
	return best_dir.normalized()


func _is_pos_walkable(world_pos: Vector3) -> bool:
	return terrain.is_walkable_world(world_pos)

func _rotate_towards(a: float, b: float, max_step: float) -> float:
	var diff := wrapf(b - a, -PI, PI)
	diff = clamp(diff, -max_step, max_step)
	return a + diff
