extends Area3D
class_name CreatureSense

## Clean creature sensing system for detecting plants and other entities.
## Handles field of view calculations and target acquisition.

signal targets_changed()

@export_group("Detection")
@export var field_of_view_degrees: float = 110.0
@export_node_path("Node3D") var head_node_path: NodePath

@export_group("Debug")
@export var debug_mode: bool = false

# Internal state
var detected_plants: Array[Plant] = []
var head_node: Node3D

func _ready() -> void:
	_connect_area_signals()
	_setup_head_reference()

func _connect_area_signals() -> void:
	area_entered.connect(_on_detection_area_entered)
	area_exited.connect(_on_detection_area_exited)

func _setup_head_reference() -> void:
	if head_node_path != NodePath():
		head_node = get_node(head_node_path) as Node3D
		
	if debug_mode:
		print("[CreatureSense] Initialized - monitoring=%s mask=%s head_connected=%s" % [
			monitoring, collision_mask, head_node != null
		])

func _on_detection_area_entered(area: Area3D) -> void:
	if debug_mode:
		print("[CreatureSense] Area entered: %s" % area.name)
	
	var plant = _find_plant_from_area(area)
	if plant and not detected_plants.has(plant):
		detected_plants.append(plant)
		targets_changed.emit()
		
		if debug_mode:
			print("[CreatureSense] Added plant: %s (total: %d)" % [plant.name, detected_plants.size()])

func _on_detection_area_exited(area: Area3D) -> void:
	if debug_mode:
		print("[CreatureSense] Area exited: %s" % area.name)
	
	var plant = _find_plant_from_area(area)
	if plant and detected_plants.has(plant):
		detected_plants.erase(plant)
		targets_changed.emit()
		
		if debug_mode:
			print("[CreatureSense] Removed plant: %s (total: %d)" % [plant.name, detected_plants.size()])

## Find the best visible target within field of view
func get_visible_target(observer: Node3D) -> Plant:
	var eye_position = _get_eye_position(observer)
	var forward_direction = _get_forward_direction(observer)
	var fov_cosine_limit = cos(deg_to_rad(field_of_view_degrees) * 0.5)
	
	var best_plant: Plant = null
	var closest_distance_squared = INF
	
	# Clean up invalid references and find closest visible target
	_cleanup_invalid_plants()
	
	for plant in detected_plants:
		var direction_to_plant = (plant.global_transform.origin - eye_position)
		direction_to_plant.y = 0.0  # Ignore height differences
		
		var distance_squared = direction_to_plant.length_squared()
		if distance_squared <= 0.0001:  # Too close/same position
			continue
		
		var normalized_direction = direction_to_plant.normalized()
		
		# Check if plant is within field of view
		if forward_direction.dot(normalized_direction) < fov_cosine_limit:
			continue
		
		# Track closest plant within FOV
		if distance_squared < closest_distance_squared:
			closest_distance_squared = distance_squared
			best_plant = plant
	
	return best_plant

## Check if a specific plant is currently in detection range
func is_in_range(plant: Plant) -> bool:
	if not plant or not is_instance_valid(plant):
		return false
	return detected_plants.has(plant)

## Get all detected plants (cleaned of invalid references)
func get_detected_plants() -> Array[Plant]:
	_cleanup_invalid_plants()
	return detected_plants.duplicate()

func _find_plant_from_area(area: Area3D) -> Plant:
	var current_node: Node = area.get_parent()
	
	# Walk up the scene tree to find a Plant node
	while current_node != null:
		if current_node is Plant:
			return current_node as Plant
		current_node = current_node.get_parent()
	
	if debug_mode:
		print("[CreatureSense] Warning: Could not find Plant parent for area: %s" % area.name)
	
	return null

func _get_eye_position(observer: Node3D) -> Vector3:
	if head_node:
		return head_node.global_transform.origin
	return observer.global_transform.origin

func _get_forward_direction(observer: Node3D) -> Vector3:
	var reference_node = head_node if head_node else observer
	return -reference_node.global_transform.basis.z  # Godot's forward is -Z

func _cleanup_invalid_plants() -> void:
	var initial_count = detected_plants.size()
	
	# Remove invalid plant references
	for i in range(detected_plants.size() - 1, -1, -1):
		var plant = detected_plants[i]
		if not plant or not is_instance_valid(plant):
			detected_plants.remove_at(i)
	
	# Emit signal if any plants were removed
	if detected_plants.size() != initial_count:
		targets_changed.emit()
