extends Plant
class_name FruitTree

func _ready() -> void:
	super._ready()
	energy_value = 40  # More nutritious than regular plants
	
	# Scale up the fruit tree
	scale = Vector3(1.5, 1.5, 1.5)
	
	# Give it a brown/orange color
	var mesh_instance = get_child(0) as MeshInstance3D
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			material.albedo_color = Color(0.8, 0.6, 0.3, 1.0)