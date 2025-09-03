extends Area3D
class_name CreatureSense

signal changed()

@export var fov_deg: float = 110.0
@export var debug: bool = false
@export_node_path("Node3D") var head_path: NodePath	# optional: use your Head for facing

var in_range: Array[Plant] = []
var head: Node3D = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	if head_path != NodePath():
		head = get_node(head_path) as Node3D
		print("[Sense] ready: monitoring=", monitoring, " mask=", collision_mask, " head_ok=", head != null)


func _on_area_entered(other: Area3D) -> void:
	print("[Sense] area_entered: ", other.name)

	var p := _area_to_plant(other)
	print("[Sense] parent found: ", p)

	if p != null and not in_range.has(p):
		in_range.append(p)
		if debug:
			print("[Sense] +", p.name, " (#", in_range.size(), ")")
		changed.emit()

func _on_area_exited(other: Area3D) -> void:
	print("[Sense] area_exited: ", other.name)

	var p := _area_to_plant(other)
	if p != null and in_range.has(p):
		in_range.erase(p)
		if debug:
			print("[Sense] -", p.name, " (#", in_range.size(), ")")
		changed.emit()

func _area_to_plant(a: Area3D) -> Plant:
	var n: Node = a.get_parent()
	# Walk up until we find a Plant (handles any intermediate wrappers)
	while n != null and not (n is Plant):
		n = n.get_parent()
	if n == null:
		print("[Sense] WARN: could not find Plant for area: ", a)
	return n as Plant


func get_visible_target(from_node: Node3D) -> Plant:
	var eye_node := head if head != null else from_node
	var eye := eye_node.global_transform.origin
	var forward := -eye_node.global_transform.basis.z	# Godot forward = -Z
	var cos_limit := cos(deg_to_rad(fov_deg) * 0.5)

	var best: Plant = null
	var best_d2 := INF

	# prune dead refs; pick nearest inside FOV
	for i in range(in_range.size() - 1, -1, -1):
		var p := in_range[i]
		if p == null or not is_instance_valid(p):
			in_range.remove_at(i)
			continue

		var to := p.global_transform.origin - eye
		to.y = 0.0
		var d2 := to.length_squared()
		if d2 <= 0.0001:
			continue

		var dir := to.normalized()
		if forward.dot(dir) < cos_limit:
			continue

		if d2 < best_d2:
			best_d2 = d2
			best = p

	return best

func is_in_range(p: Plant) -> bool:
	if p == null or not is_instance_valid(p):
		return false
	return in_range.has(p)
