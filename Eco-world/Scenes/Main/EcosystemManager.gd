extends Node
class_name EcosystemManager

@export var terrain_path: NodePath = NodePath("../EcoMap3D/GridMap")
@export var herbivore_scene: PackedScene
@export var carnivore_scene: PackedScene
@export var plant_scene: PackedScene
@export var fruit_tree_scene: PackedScene
@export var fruit_tree_spawn_chance: float = 0.3  # 30% chance for fruit trees

@export var initial_herbivores: int = 4
@export var initial_carnivores: int = 1
@export var initial_plants: int = 20
@export var plant_regrow_time: float = 6.0
@export var max_plants: int = 30

# Population dynamics
@export var herbivore_reproduction_energy: int = 150
@export var reproduction_cooldown: float = 15.0
@export var max_herbivores: int = 8

var terrain: GridMap
var rng := RandomNumberGenerator.new()
var plant_regrow_timer: float = 0.0
var reproduction_timer: float = 0.0

func _ready() -> void:
	terrain = get_node(terrain_path) as GridMap
	if not terrain:
		push_error("Could not find terrain at path: " + str(terrain_path))
		return
	
	rng.randomize()
	
	# Spawn initial ecosystem
	_spawn_initial_plants()
	_spawn_initial_herbivores()
	_spawn_initial_carnivores()
	
	print("Ecosystem initialized: ", initial_herbivores, " herbivores, ", initial_carnivores, " carnivores, ", initial_plants, " plants")

func _process(delta: float) -> void:
	# Handle plant regrowth
	plant_regrow_timer -= delta
	if plant_regrow_timer <= 0.0:
		_try_regrow_plant()
		plant_regrow_timer = plant_regrow_time
	
	# Handle reproduction
	reproduction_timer -= delta
	if reproduction_timer <= 0.0:
		_try_reproduce_herbivores()
		reproduction_timer = reproduction_cooldown

func _spawn_initial_plants() -> void:
	for i in initial_plants:
		_spawn_plant()

func _spawn_initial_creatures() -> void:
	for i in initial_creatures:
		_spawn_creature()

func _spawn_plant() -> void:
	# Randomly choose between regular plants and fruit trees
	var scene_to_use = plant_scene
	if fruit_tree_scene and rng.randf() < fruit_tree_spawn_chance:
		scene_to_use = fruit_tree_scene
	
	if not scene_to_use:
		return
	
	var cell = terrain.get_random_walkable_cell(rng)
	var plant = scene_to_use.instantiate() as Plant
	add_child(plant)
	plant.place_on_cell(cell, terrain)
	plant.consumed.connect(_on_plant_consumed)

func _try_regrow_plant() -> void:
	var current_plants = get_tree().get_nodes_in_group("plants").size()
	if current_plants < max_plants:
		_spawn_plant()

func _on_plant_consumed(plant: Plant) -> void:
	# Plant will be freed automatically by Plant.consume()
	# Regrowth is handled by the timer system
	pass

func _try_reproduce_herbivores() -> void:
	var herbivores = get_tree().get_nodes_in_group("herbivores")
	if herbivores.size() >= max_herbivores:
		return
	
	# Find herbivores with enough energy to reproduce
	for herbivore in herbivores:
		if herbivore is Herbivore and herbivore.energy >= herbivore_reproduction_energy:
			herbivore.energy -= herbivore_reproduction_energy / 2
			_spawn_herbivore()
			print("Herbivore reproduced! Population: ", herbivores.size() + 1)
			break

func get_ecosystem_stats() -> Dictionary:
	return {
		"herbivores": get_tree().get_nodes_in_group("herbivores").size(),
		"carnivores": get_tree().get_nodes_in_group("carnivores").size(),
		"plants": get_tree().get_nodes_in_group("plants").size(),
		"terrain_cells": terrain._used_cells.size()
	}