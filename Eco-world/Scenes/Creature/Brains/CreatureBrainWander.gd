extends Node
class_name CreatureBrainWander

## Legacy compatibility wrapper for the old CreatureBrainWander class.
## Redirects to the new CreatureBrain system while maintaining the same interface.

signal state_changed(state: int)

# Legacy state enum for backward compatibility  
enum MoveState { WALK, IDLE, TURN }

# Redirect to the new brain system
var modern_brain: CreatureBrain

func _ready() -> void:
	# Create the modern brain system
	modern_brain = CreatureBrain.new()
	modern_brain.name = "ModernBrain"
	add_child(modern_brain)
	
	# Connect state changes to emit legacy signals
	modern_brain.state_machine.state_changed.connect(_on_modern_brain_state_changed)
	
	print("[CreatureBrainWander] Legacy wrapper initialized, using modern CreatureBrain")

func start() -> void:
	# Legacy method - the modern brain starts automatically
	pass

func update(delta: float, current_heading: Vector3) -> Dictionary:
	# Delegate to modern brain
	if modern_brain:
		return modern_brain.update_brain(delta, current_heading)
	
	# Fallback
	return {"desired_heading": current_heading, "do_move": true}

func _on_modern_brain_state_changed(from_state: int, to_state: int) -> void:
	# Convert modern states to legacy states for backward compatibility
	var legacy_state = _modern_to_legacy_state(to_state)
	state_changed.emit(legacy_state)

func _modern_to_legacy_state(modern_state: int) -> int:
	match modern_state:
		CreatureBrain.MovementState.IDLE:
			return MoveState.IDLE
		CreatureBrain.MovementState.WANDER:
			return MoveState.WALK  
		CreatureBrain.MovementState.TURN_IN_PLACE:
			return MoveState.TURN
		CreatureBrain.MovementState.SEEK_FOOD:
			return MoveState.WALK  # Seeking appears as walking to legacy systems
		CreatureBrain.MovementState.CONSUME_FOOD:
			return MoveState.IDLE  # Consuming appears as idle
		_:
			return MoveState.WALK