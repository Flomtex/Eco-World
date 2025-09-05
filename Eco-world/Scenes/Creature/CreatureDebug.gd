extends Label
class_name CreatureDebug

## Clean debug display for creature state information.
## Shows current AI state and other relevant creature data.

@export_node_path("StateMachine") var state_machine_path: NodePath = ^"../Brain/StateMachine"

# Component references
var state_machine: StateMachine

# State display mapping for better readability
var state_display_names = {
	0: "IDLE",
	1: "WANDER", 
	2: "TURN",
	3: "SEEK_FOOD",
	4: "CONSUME_FOOD"
}

func _ready() -> void:
	_initialize_references()
	_setup_default_display()

func _initialize_references() -> void:
	if state_machine_path != NodePath():
		# Wait a frame for the state machine to be created
		await get_tree().process_frame
		state_machine = get_node(state_machine_path) as StateMachine
		
		if state_machine:
			state_machine.state_changed.connect(_on_state_changed)
		else:
			push_warning("CreatureDebug: StateMachine not found at path: %s" % state_machine_path)

func _setup_default_display() -> void:
	text = "INITIALIZING"
	
	# Set up clean debug text styling
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_shadow_color", Color.BLACK)
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)

func _on_state_changed(from_state: int, to_state: int) -> void:
	_update_display()

func _update_display() -> void:
	if not state_machine:
		text = "NO_STATE_MACHINE"
		return
	
	var current_state = state_machine.current_state
	var state_time = state_machine.get_state_time()
	
	var display_name = state_display_names.get(current_state, "UNKNOWN_%d" % current_state)
	text = "%s (%.1fs)" % [display_name, state_time]

## Manually update display (useful for polling-based updates)
func update_display() -> void:
	_update_display()

## Add custom state name mapping
func add_state_display_name(state_id: int, display_name: String) -> void:
	state_display_names[state_id] = display_name
