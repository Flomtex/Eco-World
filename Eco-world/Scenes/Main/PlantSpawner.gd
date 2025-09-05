extends Node
class_name PlantSpawner

## Clean plant spawning and management system.
## Handles initial plant population and respawning mechanics.

@export_group("Spawning Configuration")
@export_node_path("TerrainMap") var terrain_map_path: NodePath
@export var plant_scene: PackedScene
@export var target_plant_count: int = 20
@export var respawn_delay_seconds: float = 10.0

@export_group("Randomization")
@export var use_random_seed: bool = true
@export var spawn_seed: int = 42
@export var max_spawn_attempts: int = 200

# Component references
var terrain: TerrainMap
var rng: RandomNumberGenerator

# Active plants tracking
var active_plants: Array[Plant] = []

func _ready() -> void:
	_initialize_dependencies()
	_setup_random_generator()
	_spawn_initial_plants()

func _initialize_dependencies() -> void:
	if terrain_map_path == NodePath():
		push_error("PlantSpawner: terrain_map_path must be set")
		return
		
	terrain = get_node(terrain_map_path) as TerrainMap
	if not terrain:
		push_error("PlantSpawner: TerrainMap not found at path: %s" % terrain_map_path)
		
	if not plant_scene:
		push_error("PlantSpawner: plant_scene must be assigned")

func _setup_random_generator() -> void:
	rng = RandomNumberGenerator.new()
	
	if use_random_seed:
		rng.randomize()
	else:
		rng.seed = spawn_seed

func _spawn_initial_plants() -> void:
	if not terrain or not plant_scene:
		return
	
	var plants_spawned = 0
	var spawn_attempts = 0
	var max_total_attempts = target_plant_count * 12  # Safety limit
	
	while plants_spawned < target_plant_count and spawn_attempts < max_total_attempts:
		spawn_attempts += 1
		
		var spawn_cell = terrain.pick_spawn_cell_near_rock(rng, max_spawn_attempts)
		if spawn_cell == null:
			continue  # No valid spawn location found
		
		var plant = _create_plant_at_cell(spawn_cell)
		if plant:
			plants_spawned += 1
	
	print("[PlantSpawner] Spawned %d/%d plants (attempts: %d)" % [
		plants_spawned, target_plant_count, spawn_attempts
	])

func _create_plant_at_cell(cell: Vector3i) -> Plant:
	var plant_instance = plant_scene.instantiate() as Plant
	if not plant_instance:
		push_error("PlantSpawner: Failed to instantiate plant scene")
		return null
	
	add_child(plant_instance)
	plant_instance.place_on_cell(cell, terrain)
	plant_instance.consumed.connect(_on_plant_consumed)
	
	active_plants.append(plant_instance)
	return plant_instance

func _on_plant_consumed(consumed_plant: Plant) -> void:
	# Remove from active tracking
	if consumed_plant in active_plants:
		active_plants.erase(consumed_plant)
	
	# Schedule respawn
	_schedule_plant_respawn(consumed_plant.get_cell())

func _schedule_plant_respawn(old_cell: Vector3i) -> void:
	if respawn_delay_seconds <= 0.0:
		return  # Respawning disabled
	
	# Wait for respawn delay
	await get_tree().create_timer(respawn_delay_seconds).timeout
	
	# Find new spawn location (avoid respawning in same cell)
	var respawn_cell = _find_respawn_location(old_cell)
	if respawn_cell != null:
		var respawned_plant = _create_plant_at_cell(respawn_cell)
		if respawned_plant and not active_plants.has(respawned_plant):
			active_plants.append(respawned_plant)

func _find_respawn_location(avoid_cell: Vector3i) -> Variant:
	var attempts = 0
	var max_attempts = 400
	
	while attempts < max_attempts:
		attempts += 1
		
		var candidate_cell = terrain.pick_spawn_cell_near_rock(rng, max_spawn_attempts)
		if candidate_cell == null:
			continue
		
		# Ensure we don't respawn in the same cell
		if candidate_cell != avoid_cell:
			return candidate_cell
	
	# If we couldn't find a different cell, allow same cell respawn
	return terrain.pick_spawn_cell_near_rock(rng, max_spawn_attempts)

## Get count of currently active plants
func get_active_plant_count() -> int:
	# Clean up any invalid references
	active_plants = active_plants.filter(func(plant): return plant and is_instance_valid(plant))
	return active_plants.size()

## Manually spawn additional plants (useful for testing)
func spawn_additional_plants(count: int) -> int:
	var spawned = 0
	
	for i in range(count):
		var spawn_cell = terrain.pick_spawn_cell_near_rock(rng, max_spawn_attempts)
		if spawn_cell != null:
			var plant = _create_plant_at_cell(spawn_cell)
			if plant:
				spawned += 1
	
	return spawned
	
