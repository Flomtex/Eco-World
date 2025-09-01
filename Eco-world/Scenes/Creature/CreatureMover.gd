extends Node

class_name CreatureMover

@export var move_speed: float = 2.8
@export var turn_speed: float = 4.0
@export var lookahead: float = 0.75
@export var sample_directions: int = 16

@onready var actor: Node3D = get_parent() as Node3D
@onready var terrain: Node = get_tree().get_first_node_in_group("terrain")

var heading: Vector3 = Vector3.FORWARD
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func setup_initial_heading() -> void:
	var yaw0 := rng.randf_range(0.0, TAU)
	heading = Vector3(sin(yaw0), 0.0, cos(yaw0)).normalized()

func snap_to_ground_if_needed() -> void:
	var start_cell: Vector3i = terrain.world_to_ground_cell(actor.global_transform.origin)
	if not terrain.is_walkable_cell(start_cell):
		for off in [
			Vector3i(1,0,0), Vector3i(-1,0,0),
			Vector3i(0,0,1), Vector3i(0,0,-1),
			Vector3i(1,0,1), Vector3i(1,0,-1), Vector3i(-1,0,1), Vector3i(-1,0,-1)
		]:
			var c := Vector3i(start_cell.x + off.x, start_cell.y, start_cell.z + off.z)
			if terrain.is_walkable_cell(c):
				var snap: Vector3 = terrain.cell_to_world(c)
				actor.global_transform.origin.x = snap.x
				actor.global_transform.origin.z = snap.z
				break

func step(preferred_dir: Vector3, do_move: bool, delta: float) -> void:
	var desired_dir := _pick_walkable_direction(preferred_dir)
	if desired_dir == Vector3.ZERO:
		return

	var current_yaw := atan2(heading.x, heading.z)
	var target_yaw := atan2(desired_dir.x, desired_dir.z)
	var new_yaw := _rotate_towards(current_yaw, target_yaw, turn_speed * delta)
	heading = Vector3(sin(new_yaw), 0.0, cos(new_yaw)).normalized()

	# Face travel direction (Godot forward = -Z)
	var face_yaw := atan2(heading.x, heading.z) + PI
	actor.rotation.y = face_yaw

	if do_move:
		var step_vec := heading * move_speed * delta
		var next_pos := actor.global_transform.origin + step_vec
		if _is_pos_walkable(next_pos):
			actor.global_transform.origin = next_pos

func _pick_walkable_direction(preferred: Vector3) -> Vector3:
	var fwd := actor.global_transform.origin + preferred.normalized() * lookahead
	if _is_pos_walkable(fwd):
		return preferred.normalized()

	var best_dir := Vector3.ZERO
	var best_dot := -1.0
	var start_angle := rng.randf_range(0.0, TAU)
	for i in range(sample_directions):
		var t := float(i) / float(max(1, sample_directions))
		var ang := start_angle + t * TAU
		var dir := Vector3(sin(ang), 0.0, cos(ang))
		var probe := actor.global_transform.origin + dir * lookahead
		if _is_pos_walkable(probe):
			var d := dir.dot(preferred.normalized())
			if d > best_dot:
				best_dot = d
				best_dir = dir
	return best_dir.normalized()

func _is_pos_walkable(world_pos: Vector3) -> bool:
	return terrain.is_walkable_world(world_pos)

func _rotate_towards(a: float, b: float, max_step: float) -> float:
	var diff := wrapf(b - a, -PI, PI)
	diff = clamp(diff, -max_step, max_step)
	return a + diff
