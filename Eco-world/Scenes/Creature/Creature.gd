extends Node3D
class_name Creature

## Main creature controller that coordinates movement, AI, and sensors.
## Uses a component-based architecture with clean separation of concerns.

@export_group("Components")
@export_node_path("CreatureMover") var mover_path: NodePath = ^"Mover"
@export_node_path("CreatureBrain") var brain_path: NodePath = ^"Brain"

# Component references
var mover: CreatureMover
var brain: CreatureBrain

func _ready() -> void:
	_initialize_components()
	_setup_creature()

func _initialize_components() -> void:
	# Get component references
	mover = get_node(mover_path) as CreatureMover
	brain = get_node(brain_path) as CreatureBrain
	
	# Validate components
	if not mover:
		push_error("Creature: CreatureMover component not found at path: %s" % mover_path)
	if not brain:
		push_error("Creature: CreatureBrain component not found at path: %s" % brain_path)

func _setup_creature() -> void:
	if mover:
		mover.setup_initial_heading()
		mover.snap_to_ground_if_needed()

func _physics_process(delta: float) -> void:
	if not mover or not brain:
		return
	
	# Get movement command from brain
	var movement_command = brain.update_brain(delta, mover.get_heading())
	
	# Execute movement
	var desired_heading: Vector3 = movement_command.get("desired_heading", Vector3.FORWARD)
	var should_move: bool = movement_command.get("do_move", false)
	
	mover.step_movement(desired_heading, should_move, delta)
