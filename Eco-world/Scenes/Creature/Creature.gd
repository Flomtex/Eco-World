extends Node3D


@onready var mover: CreatureMover = $Mover
@onready var brain_wander: CreatureBrainWander = $BrainWander

func _ready() -> void:
	mover.setup_initial_heading()
	mover.snap_to_ground_if_needed()
	brain_wander.start()

func _physics_process(delta: float) -> void:
	var result: Dictionary = brain_wander.update(delta, mover.heading)
	var desired: Vector3 = result["desired_heading"]
	var do_move: bool = result["do_move"]
	mover.step(desired, do_move, delta)
