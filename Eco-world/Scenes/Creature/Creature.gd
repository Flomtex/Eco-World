extends Node3D

@export var step_seconds: float = 0.5  # time between steps

var terrain: Node = null               # your GridMap (in group "terrain") with TerrainMap.gd
var current_cell: Vector3i
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	terrain = get_tree().get_first_node_in_group("terrain")
	assert(terrain != null, "Creature: No node in group 'terrain' found (GridMap).")

	# Snap to grid:
	current_cell = terrain.world_to_cell(global_position)
	global_position = terrain.cell_to_world(current_cell)

	# Warn if starting on non-walkable (e.g., water).
	if not terrain.is_walkable_cell(current_cell):
		push_warning("Creature spawned on a non-walkable cell. Place it on GRASS or ROCK.")

	# Start simple wander loop without blocking _ready:
	call_deferred("_wander")

func _wander() -> void:
	while true:
		# Optionally "drink" if water adjacent:
		if _maybe_drink():
			await get_tree().create_timer(step_seconds).timeout
			continue

		var next_cell := _pick_next_cell()
		if next_cell != current_cell:
			_move_to_cell(next_cell)

		await get_tree().create_timer(step_seconds).timeout

func _pick_next_cell() -> Vector3i:
	var options: Array[Vector3i] = []
	for c: Vector3i in terrain.neighbors4(current_cell):
		if terrain.is_walkable_cell(c):
			options.append(c)
	if options.is_empty():
		return current_cell
	return options[rng.randi_range(0, options.size() - 1)]

func _move_to_cell(cell: Vector3i) -> void:
	if not terrain.is_walkable_cell(cell):
		return
	current_cell = cell
	global_position = terrain.cell_to_world(cell)

func _maybe_drink() -> bool:
	for c: Vector3i in terrain.neighbors4(current_cell):
		if terrain.provides_water(c):
			if rng.randf() < 0.30:
				print("Creature drinks at cell ", current_cell, " next to water at ", c)
				return true
	return false
