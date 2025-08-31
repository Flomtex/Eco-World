@tool
extends EditorScript

const WIDTH: int  = 64
const HEIGHT: int = 64
const LAYER_Y: int = 0
const NOISE_SCALE: float = 0.075
const NOISE_SEED: int = 1337
const WATER_THRESHOLD: float = 0.35
const GRASS_THRESHOLD: float = 0.62

const ROCK_ID := 0
const GRASS_ID := 1
const WATER_ID := 2

func _run() -> void:
	var grid := _get_selected_gridmap()
	if grid == null:
		push_error("Select a GridMap node in the Scene tree, then run this script.")
		return
	if grid.mesh_library == null:
		push_error("Selected GridMap has no MeshLibrary assigned.")
		return

	_clear_grid(grid)

	var noise := FastNoiseLite.new()
	noise.seed = NOISE_SEED
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = NOISE_SCALE

	for y in HEIGHT:
		for x in WIDTH:
			var n := (noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			var item_id := ROCK_ID
			if n <= WATER_THRESHOLD: item_id = WATER_ID
			elif n <= GRASS_THRESHOLD: item_id = GRASS_ID
			grid.set_cell_item(Vector3i(x, LAYER_Y, y), item_id)

	print("Eco grid generated: %dx%d at layer y=%d" % [WIDTH, HEIGHT, LAYER_Y])

func _clear_grid(grid: GridMap) -> void:
	for c in grid.get_used_cells():
		grid.set_cell_item(c, GridMap.INVALID_CELL_ITEM)

func _get_selected_gridmap() -> GridMap:
	var ed := get_editor_interface()
	for n in ed.get_selection().get_selected_nodes():
		if n is GridMap: return n
	return null
