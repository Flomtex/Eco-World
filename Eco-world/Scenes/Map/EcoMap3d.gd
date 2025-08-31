extends Node3D

func _ready() -> void:
	var tm := $GridMap as TerrainMap
	assert(tm != null)

	# Simple counts using existing API
	var water := 0
	var walkable := 0
	for cell in tm.get_used_cells():
		if tm.get_cell_type(cell) == TerrainMap.Tile.WATER:
			water += 1
		else:
			walkable += 1

	print("walkable=", walkable, "  water=", water)

	var c := Vector3i(0, 0, 0)
	print("type@(0,0,0)=", tm.get_cell_type(c), "  walkable=", tm.is_walkable_cell(c))

	get_tree().quit() # optional: close after printing
