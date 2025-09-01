extends Label

@onready var brain: CreatureBrainWander = $"../BrainWander"

static func _state_name(s: int) -> String:
	match s:
		0: return "WALK"
		1: return "IDLE"
		2: return "TURN"
		_: return str(s)

func _ready() -> void:
	text = "WALK"
	brain.state_changed.connect(_on_state_changed)

func _on_state_changed(s: int) -> void:
	text = _state_name(s)
