extends Node
class_name EcosystemManager

@export var terrain_path: NodePath = NodePath("../EcoMap3D/GridMap")
@export var creature_scene: PackedScene
@export var plant_scene: PackedScene

@export var initial_creatures: int = 3
@export var initial_plants: int = 15
@export var plant_regrow_time: float = 8.0
@export var max_plants: int = 25

var terrain: GridMap
var rng := RandomNumberGenerator.new()
var plant_regrow_timer: float = 0.0

func _ready() -> void:
	terrain = get_node(terrain_path) as GridMap
	if not terrain:
		push_error("Could not find terrain at path: " + str(terrain_path))
		return
	
	rng.randomize()
	
	# Spawn initial ecosystem
	_spawn_initial_plants()
	_spawn_initial_creatures()
	
	print("Ecosystem initialized: ", initial_creatures, " creatures, ", initial_plants, " plants")

func _process(delta: float) -> void:
	# Handle plant regrowth
	plant_regrow_timer -= delta
	if plant_regrow_timer <= 0.0:
		_try_regrow_plant()
		plant_regrow_timer = plant_regrow_time

func _spawn_initial_plants() -> void:
	for i in initial_plants:
		_spawn_plant()

func _spawn_initial_creatures() -> void:
	for i in initial_creatures:
		_spawn_creature()

func _spawn_plant() -> void:
	if not plant_scene:
		return
	
	var cell = terrain.get_random_walkable_cell(rng)
	var plant = plant_scene.instantiate() as Plant
	add_child(plant)
	plant.place_on_cell(cell, terrain)
	plant.consumed.connect(_on_plant_consumed)

func _spawn_creature() -> void:
	if not creature_scene:
		return
		
	var cell = terrain.get_random_walkable_cell(rng)
	var world_pos = terrain.cell_to_world(cell)
	
	var creature = creature_scene.instantiate()
	add_child(creature)
	creature.global_position = world_pos

func _try_regrow_plant() -> void:
	var current_plants = get_tree().get_nodes_in_group("plants").size()
	if current_plants < max_plants:
		_spawn_plant()

func _on_plant_consumed(plant: Plant) -> void:
	# Plant will be freed automatically by Plant.consume()
	# Regrowth is handled by the timer system
	pass

func get_ecosystem_stats() -> Dictionary:
	return {
		"creatures": get_children().filter(func(n): return n.has_method("_seek_food")).size(),
		"plants": get_tree().get_nodes_in_group("plants").size(),
		"terrain_cells": terrain._used_cells.size()
	}