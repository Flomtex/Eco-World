extends SimplifiedCreature
class_name Herbivore

func _ready() -> void:
	super._ready()
	# Herbivores are smaller and faster
	move_speed = 2.5
	turn_speed = 4.0
	sensor_range = 4.0
	energy = 80
	hunger_threshold = 25
	
	add_to_group("herbivores")  # Add to group for carnivores to find
	
	# Give herbivores a green tint
	var body = $Body as MeshInstance3D
	if body and body.material_override:
		var material = body.material_override as StandardMaterial3D
		if material:
			material.albedo_color = Color.GREEN