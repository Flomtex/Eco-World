extends Node

@export_node_path("GridMap") var terrain_map_path: NodePath   # /Main/EcoMap3D/GridMap
@export var plant_scene: PackedScene                           # res://Scenes/Plant/Plant.tscn
@export var spawn_count: int = 20
@export var rng_seed: int = 42
@export var randomize_on_ready: bool = true
@export var respawn_delay: float = 10.0                         # seconds

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	var terrain: Node = get_node(terrain_map_path)

	if randomize_on_ready:
		rng.randomize()
	else:
		rng.seed = rng_seed

	var spawned := 0
	var tries := 0
	while spawned < spawn_count and tries < spawn_count * 12:
		tries += 1
		var cell = terrain.pick_spawn_cell_near_rock(rng, 200)  # can be null
		if cell == null:
			continue
		var p := plant_scene.instantiate() as Plant
		add_child(p)
		p.place_on_cell(cell, terrain)
		p.consumed.connect(_on_plant_consumed)
		spawned += 1

	print("PlantSpawner: spawned %d plants (target=%d, tries=%d)" % [spawned, spawn_count, tries])

func _on_plant_consumed(plant: Plant) -> void:
	var terrain: Node = get_node(terrain_map_path)
	var old_cell := plant.cell
	await get_tree().create_timer(respawn_delay).timeout

	var cell = null
	var guard := 0
	while (cell == null or cell == old_cell) and guard < 400:
		cell = terrain.pick_spawn_cell_near_rock(rng, 200)
		guard += 1
	if cell == null:
		return

	var p := plant_scene.instantiate() as Plant
	add_child(p)
	p.place_on_cell(cell, terrain)
	p.consumed.connect(_on_plant_consumed)
	
