extends Resource

class_name GridPath


static func plan(start: Vector3i, goal: Vector3i, terrain: TerrainMap, max_steps: int = 8192) -> Array[Vector3i]:
	var path: Array[Vector3i] = []
	if start == goal:
		return path

	var open: Array[Vector3i] = [start]
	var came_from: Dictionary = {}
	var g: Dictionary = {start: 0}
	var f: Dictionary = {start: _h_octile(start, goal)}
	var closed: Dictionary = {}
	var steps := 0

	while open.size() > 0 and steps < max_steps:
		steps += 1
		# pick node with lowest f
		var current: Vector3i = open[0]
		var best_f := float(f.get(current, INF))
		for i in range(1, open.size()):
			var c: Vector3i = open[i]
			var fi := float(f.get(c, INF))
			if fi < best_f:
				best_f = fi
				current = c

		if current == goal:
			# reconstruct path (excludes start, includes goal)
			var cur := current
			while came_from.has(cur):
				path.push_front(cur)
				cur = came_from[cur]
			return path

		open.erase(current)
		closed[current] = true

		for step in _neighbors8(current, terrain): # orth+diag; no corner-cutting
			var n: Vector3i = step.cell
			var step_cost: int = step.cost   # 10 orth, 14 diag
			if not terrain.is_walkable_cell(n):
				continue
			if closed.has(n):
				continue

			var tentative_g: int = int(g[current]) + step_cost
			if not g.has(n) or tentative_g < int(g[n]):
				came_from[n] = current
				g[n] = tentative_g
				f[n] = tentative_g + _h_octile(n, goal)
				if not open.has(n):
					open.append(n)



	return []  # no path

static func _h(a: Vector3i, b: Vector3i) -> int:
	# Manhattan distance (works with 4-neighbour grid)
	return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)

static func _neighbors8(c: Vector3i, terrain: TerrainMap) -> Array:
	var out: Array = []
	# Orthogonal (cost 10)
	const ORTH = [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]
	for d in ORTH:
		out.append({"cell": c + d, "cost": 10})

	# Diagonals (cost 14), no corner-cutting: both touching orth cells must be walkable
	const DIAG = [Vector3i(1,0,1), Vector3i(1,0,-1), Vector3i(-1,0,1), Vector3i(-1,0,-1)]
	for d in DIAG:
		var n = c + d
		var a := Vector3i(c.x + d.x, c.y, c.z)   # orth X neighbour
		var b := Vector3i(c.x, c.y, c.z + d.z)   # orth Z neighbour
		if terrain.is_walkable_cell(a) and terrain.is_walkable_cell(b):
			out.append({"cell": n, "cost": 14})
	return out

static func _h_octile(a: Vector3i, b: Vector3i) -> int:
	var dx: int = abs(a.x - b.x)
	var dz: int = abs(a.z - b.z)
	# Octile distance with 10/14 costs
	return 10 * (dx + dz) + (14 - 20) * min(dx, dz)
