extends Node
class_name CreatureBrainWander

@export var walk_time_range: Vector2 = Vector2(1.3, 3.2)
@export var idle_time_range: Vector2 = Vector2(0.6, 1.8)
@export var turn_time_range: Vector2 = Vector2(0.25, 0.6)
@export var turn_in_place_rate: float = 90.0 * PI / 180.0
@export var jitter_deg: float = 12.0
@export var jitter_interval_range: Vector2 = Vector2(0.8, 2.0)

enum MoveState { WALK, IDLE, TURN }
var state: int = MoveState.WALK
var state_time_left: float = 0.0
var turn_dir: float = 1.0
var jitter_time_left: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func start() -> void:
	_set_state(MoveState.WALK)
	_reset_jitter_timer()

# Returns {"desired_heading": Vector3, "do_move": bool}
func update(delta: float, current_heading: Vector3) -> Dictionary:
	var h := current_heading
	state_time_left -= delta
	match state:
		MoveState.IDLE:
			if state_time_left <= 0.0:
				_set_state(MoveState.WALK if rng.randf() < 0.6 else MoveState.TURN)
			return {"desired_heading": h, "do_move": false}

		MoveState.TURN:
			var yaw := atan2(h.x, h.z)
			yaw += turn_dir * turn_in_place_rate * delta
			h = Vector3(sin(yaw), 0.0, cos(yaw)).normalized()
			if state_time_left <= 0.0:
				_set_state(MoveState.WALK)
			return {"desired_heading": h, "do_move": false}

		MoveState.WALK:
			jitter_time_left -= delta
			if jitter_time_left <= 0.0:
				var jitter := deg_to_rad(rng.randf_range(-jitter_deg, jitter_deg))
				var yaw := atan2(h.x, h.z) + jitter
				h = Vector3(sin(yaw), 0.0, cos(yaw)).normalized()
				_reset_jitter_timer()
			if state_time_left <= 0.0:
				_set_state(MoveState.IDLE if rng.randf() < 0.5 else MoveState.TURN)
			return {"desired_heading": h, "do_move": true}

	return {"desired_heading": h, "do_move": true}

func _set_state(s: int) -> void:
	state = s
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
