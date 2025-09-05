extends Node
class_name StateMachine

## A clean, extensible state machine implementation for creatures and other entities.
## Uses enum-based states with proper enter/exit callbacks and transition management.

signal state_changed(from_state: int, to_state: int)

@export var initial_state: int = 0
@export var debug_transitions: bool = false

var current_state: int = -1
var previous_state: int = -1
var state_time: float = 0.0
var states: Dictionary = {}

## State object that handles enter, update, and exit logic
class State:
	var name: String
	var enter_callback: Callable
	var update_callback: Callable  
	var exit_callback: Callable
	
	func _init(state_name: String):
		name = state_name
		
	func enter(state_machine: StateMachine) -> void:
		if enter_callback.is_valid():
			enter_callback.call()
			
	func update(state_machine: StateMachine, delta: float) -> void:
		if update_callback.is_valid():
			update_callback.call(delta)
			
	func exit(state_machine: StateMachine) -> void:
		if exit_callback.is_valid():
			exit_callback.call()

func _ready() -> void:
	if states.is_empty():
		push_warning("StateMachine has no states defined")
		return
		
	# Start with initial state
	change_state(initial_state)

func _process(delta: float) -> void:
	if current_state == -1:
		return
		
	state_time += delta
	
	if states.has(current_state):
		var state: State = states[current_state]
		state.update(self, delta)

## Add a state to the state machine
func add_state(state_id: int, state_name: String) -> State:
	var state = State.new(state_name)
	states[state_id] = state
	return state

## Change to a new state with proper enter/exit handling
func change_state(new_state: int) -> void:
	if new_state == current_state:
		return
		
	# Exit current state
	if current_state != -1 and states.has(current_state):
		var current: State = states[current_state]
		current.exit(self)
	
	previous_state = current_state
	current_state = new_state
	state_time = 0.0
	
	# Enter new state
	if states.has(current_state):
		var new: State = states[current_state]
		new.enter(self)
		
		if debug_transitions:
			print("[StateMachine] %s -> %s" % [
				_state_name(previous_state),
				_state_name(current_state)
			])
	
	state_changed.emit(previous_state, current_state)

## Get the name of a state for debugging
func _state_name(state_id: int) -> String:
	if state_id == -1:
		return "NONE"
	if states.has(state_id):
		return states[state_id].name
	return "UNKNOWN_%d" % state_id

## Check if currently in a specific state
func is_in_state(state_id: int) -> bool:
	return current_state == state_id

## Get time spent in current state
func get_state_time() -> float:
	return state_time

## Force state without transitions (use carefully)
func force_state(state_id: int) -> void:
	previous_state = current_state
	current_state = state_id
	state_time = 0.0