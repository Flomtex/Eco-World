extends Label

@onready var ecosystem: EcosystemManager = get_node("../EcosystemManager")

func _ready() -> void:
	# Position in top-left corner
	anchors_preset = Control.PRESET_TOP_LEFT
	position = Vector2(10, 10)

func _process(_delta: float) -> void:
	if ecosystem:
		var stats = ecosystem.get_ecosystem_stats()
		text = "Creatures: %d\nPlants: %d\nTerrain: %d cells" % [
			stats.creatures,
			stats.plants, 
			stats.terrain_cells
		]
	else:
		text = "Ecosystem not found"