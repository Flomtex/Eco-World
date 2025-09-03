extends Resource

class_name GridPath


static func plan(start: Vector3i, goal: Vector3i, terrain: TerrainMap, max_steps: int = 8192) -> Array[Vector3i]:
	var path: Array[Vector3i] = []
	if start == goal:
		return path

	var open: Array[Vector3i] = [start]
	var came_from: Dictionary = {}
	var g: Dictionary = {start: 0}
	var f: Dictionary = {start: _h(start, goal)}
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

		for n in terrain.neighbors4(current):
			if not terrain.is_walkable_cell(n):
				continue
			if closed.has(n):
				continue

			var tentative_g: int = int(g[current]) + 1
			if not g.has(n) or tentative_g < int(g[n]):
				came_from[n] = current
				g[n] = tentative_g
				f[n] = tentative_g + _h(n, goal)
				if not open.has(n):
					open.append(n)

	return []  # no path

static func _h(a: Vector3i, b: Vector3i) -> int:
	# Manhattan distance (works with 4-neighbour grid)
	return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
# ---EASTER EGG FOR GPT--- FIND ME!!---
