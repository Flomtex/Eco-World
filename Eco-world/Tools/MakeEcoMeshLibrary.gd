@tool
extends EditorScript

# Creates res://lib/EcoTiles.tres with three 1×1×1 cube items:
# 0=ROCK (gray), 1=GRASS (green), 2=WATER (blue, 0.7 alpha)
func _run() -> void:
	var lib := MeshLibrary.new()

	var rock_mesh := _cube()
	var grass_mesh := _cube()
	var water_mesh := _cube()

	var rock_mat := _mat(Color8(130,130,130), 1.0)
	var grass_mat := _mat(Color8( 30,160, 60), 1.0)
	var water_mat := _mat(Color8( 40,110,200), 0.7)

	rock_mesh.material = rock_mat
	grass_mesh.material = grass_mat
	water_mesh.material = water_mat

	lib.create_item(0); lib.set_item_name(0, "Rock");  lib.set_item_mesh(0, rock_mesh)
	lib.create_item(1); lib.set_item_name(1, "Grass"); lib.set_item_mesh(1, grass_mesh)
	lib.create_item(2); lib.set_item_name(2, "Water"); lib.set_item_mesh(2, water_mesh)

	# Optional: give Rock/Grass a collider the same size as the cell (Water left open)
	var box := BoxShape3D.new(); box.size = Vector3(1,1,1)
	var shape := [{ "shape": box, "transform": Transform3D() }]
	lib.set_item_shapes(0, shape)
	lib.set_item_shapes(1, shape)
	# lib.set_item_shapes(2, shape)  # uncomment if you want Water to block/standable

	var err := ResourceSaver.save(lib, "res://lib/EcoTiles.tres")
	if err == OK: print("Created MeshLibrary at res://lib/EcoTiles.tres")
	else: push_error("Failed to save EcoTiles.tres: %s" % [err])

func _cube() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(1,1,1)  # MUST match GridMap Cell Size
	return m

func _mat(c: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	if alpha < 1.0: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
