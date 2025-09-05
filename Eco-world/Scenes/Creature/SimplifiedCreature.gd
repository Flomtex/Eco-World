extends Node3D
class_name SimplifiedCreature

@export var move_speed: float = 2.0
@export var turn_speed: float = 3.0
@export var sensor_range: float = 5.0
@export var energy: int = 100
@export var hunger_threshold: int = 30

@onready var terrain: GridMap = get_tree().get_first_node_in_group("terrain")

var heading: Vector3 = Vector3.FORWARD
var target_plant: Plant = null
var wander_timer: float = 0.0
var state: String = "wander"

func _ready() -> void:
	# Initialize random heading
	var angle = randf() * TAU
	heading = Vector3(sin(angle), 0, cos(angle)).normalized()
	
	# Snap to ground
	if terrain:
		var ground_pos = terrain.world_to_ground_cell(global_position)
		global_position = terrain.cell_to_world(ground_pos)

func _physics_process(delta: float) -> void:
	# Simple state machine: hungry -> seek food, otherwise wander
	if energy <= hunger_threshold:
		state = "seeking"
		_seek_food(delta)
	else:
		state = "wander"
		_wander(delta)
	
	_move(delta)
	
	# Die if energy reaches 0
	if energy <= 0:
		print("Creature died of starvation")
		queue_free()

func _seek_food(delta: float) -> void:
	# Find nearest plant if we don't have a target
	if target_plant == null or not is_instance_valid(target_plant):
		target_plant = _find_nearest_plant()
	
	if target_plant:
		# Move toward plant
		var to_plant = target_plant.global_position - global_position
		to_plant.y = 0
		if to_plant.length() > 0.1:
			heading = to_plant.normalized()
		else:
			# Close enough to eat
			energy += target_plant.consume()
			target_plant = null
			print("Creature ate plant, energy now: ", energy)

func _wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0:
		# Change direction occasionally
		var angle_change = randf_range(-PI/4, PI/4)
		var current_angle = atan2(heading.x, heading.z)
		heading = Vector3(sin(current_angle + angle_change), 0, cos(current_angle + angle_change))
		wander_timer = randf_range(2.0, 5.0)

func _move(delta: float) -> void:
	# Simple movement with obstacle avoidance
	var desired_pos = global_position + heading * move_speed * delta
	
	if terrain and terrain.is_walkable_world(desired_pos):
		global_position = desired_pos
	else:
		# Turn when hitting obstacle
		heading = Vector3(-heading.z, 0, heading.x).normalized()  # Turn 90 degrees
	
	# Gradually turn to face movement direction
	var target_rotation = atan2(heading.x, heading.z)
	var current_rotation = rotation.y
	var angle_diff = fmod(target_rotation - current_rotation + PI, TAU) - PI
	rotation.y += sign(angle_diff) * min(abs(angle_diff), turn_speed * delta)
	
	# Lose energy over time
	energy = max(0, energy - int(delta * 2))

func _find_nearest_plant() -> Plant:
	var plants = get_tree().get_nodes_in_group("plants")
	var nearest: Plant = null
	var nearest_distance = sensor_range * sensor_range
	
	for plant in plants:
		if plant is Plant and is_instance_valid(plant):
			var distance_sq = global_position.distance_squared_to(plant.global_position)
			if distance_sq < nearest_distance:
				nearest_distance = distance_sq
				nearest = plant
	
	return nearest