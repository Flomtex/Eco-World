extends SimplifiedCreature
class_name Carnivore

@export var hunt_range: float = 6.0
var target_prey: SimplifiedCreature = null

func _ready() -> void:
	super._ready()
	# Carnivores are bigger and stronger but slower
	move_speed = 1.8
	turn_speed = 2.5
	sensor_range = hunt_range
	energy = 120
	hunger_threshold = 40
	
	add_to_group("carnivores")
	
	# Give carnivores a red tint
	var body = $Body as MeshInstance3D
	if body and body.material_override:
		var material = body.material_override as StandardMaterial3D
		if material:
			material.albedo_color = Color.RED

func _seek_food(delta: float) -> void:
	# Find prey if we don't have a target
	if target_prey == null or not is_instance_valid(target_prey):
		target_prey = _find_nearest_prey()
	
	if target_prey:
		# Move toward prey
		var to_prey = target_prey.global_position - global_position
		to_prey.y = 0
		if to_prey.length() > 0.1:
			heading = to_prey.normalized()
		else:
			# Close enough to hunt
			_hunt_prey(target_prey)
			target_prey = null
	else:
		# No prey found, wander instead
		super._wander(delta)

func _find_nearest_prey() -> SimplifiedCreature:
	var creatures = get_tree().get_nodes_in_group("herbivores")
	var nearest: SimplifiedCreature = null
	var nearest_distance = hunt_range * hunt_range
	
	for creature in creatures:
		if creature is SimplifiedCreature and creature != self and is_instance_valid(creature):
			var distance_sq = global_position.distance_squared_to(creature.global_position)
			if distance_sq < nearest_distance:
				nearest_distance = distance_sq
				nearest = creature
	
	return nearest

func _hunt_prey(prey: SimplifiedCreature) -> void:
	if is_instance_valid(prey):
		energy += 60  # More energy from hunting
		prey.queue_free()
		print("Carnivore hunted prey, energy now: ", energy)