extends Resource
class_name GridPath

## Clean A* pathfinding implementation for grid-based movement.
## Provides efficient pathfinding with diagonal movement support and corner-cutting prevention.

## Main pathfinding function - finds path from start to goal
static func plan(start_cell: Vector3i, goal_cell: Vector3i, terrain: TerrainMap, max_iterations: int = 8192) -> Array[Vector3i]:
	if start_cell == goal_cell:
		return []  # Already at destination
	
	var pathfinder = AStarPathfinder.new(terrain)
	return pathfinder.find_path(start_cell, goal_cell, max_iterations)

## Internal A* pathfinding implementation
class AStarPathfinder:
	var terrain: TerrainMap
	var open_set: Array[Vector3i]
	var came_from: Dictionary  # Vector3i -> Vector3i
	var g_score: Dictionary    # Vector3i -> float (actual cost from start)
	var f_score: Dictionary    # Vector3i -> float (estimated total cost)
	var closed_set: Dictionary # Vector3i -> bool
	
	func _init(terrain_map: TerrainMap):
		terrain = terrain_map
	
	func find_path(start: Vector3i, goal: Vector3i, max_iterations: int) -> Array[Vector3i]:
		_initialize_search(start, goal)
		
		var iterations = 0
		while not open_set.is_empty() and iterations < max_iterations:
			iterations += 1
			
			var current = _get_lowest_f_score_node()
			
			if current == goal:
				return _reconstruct_path(current)
			
			_process_node(current, goal)
		
		return []  # No path found
	
	func _initialize_search(start: Vector3i, goal: Vector3i) -> void:
		open_set = [start]
		came_from.clear()
		g_score = {start: 0}
		f_score = {start: _calculate_heuristic(start, goal)}
		closed_set.clear()
	
	func _get_lowest_f_score_node() -> Vector3i:
		var best_node = open_set[0]
		var best_score = f_score.get(best_node, INF)
		
		for i in range(1, open_set.size()):
			var node = open_set[i]
			var score = f_score.get(node, INF)
			if score < best_score:
				best_score = score
				best_node = node
		
		return best_node
	
	func _process_node(current: Vector3i, goal: Vector3i) -> void:
		open_set.erase(current)
		closed_set[current] = true
		
		var neighbors = _get_valid_neighbors(current)
		for neighbor_data in neighbors:
			var neighbor: Vector3i = neighbor_data.cell
			var movement_cost: float = neighbor_data.cost
			
			if closed_set.has(neighbor):
				continue  # Already processed
			
			var tentative_g_score = g_score[current] + movement_cost
			
			if not g_score.has(neighbor) or tentative_g_score < g_score[neighbor]:
				# This path to neighbor is better than previous
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + _calculate_heuristic(neighbor, goal)
				
				if not open_set.has(neighbor):
					open_set.append(neighbor)
	
	func _get_valid_neighbors(cell: Vector3i) -> Array:
		var neighbors: Array = []
		
		# Orthogonal neighbors (cost 10)
		var orthogonal_offsets = [
			Vector3i(1, 0, 0), Vector3i(-1, 0, 0), 
			Vector3i(0, 0, 1), Vector3i(0, 0, -1)
		]
		
		for offset in orthogonal_offsets:
			var neighbor = cell + offset
			if terrain.is_walkable_cell(neighbor):
				neighbors.append({"cell": neighbor, "cost": 10.0})
		
		# Diagonal neighbors (cost 14) with corner-cutting prevention
		var diagonal_offsets = [
			Vector3i(1, 0, 1), Vector3i(1, 0, -1),
			Vector3i(-1, 0, 1), Vector3i(-1, 0, -1)
		]
		
		for offset in diagonal_offsets:
			var neighbor = cell + offset
			if terrain.is_walkable_cell(neighbor):
				# Prevent corner-cutting: both adjacent orthogonal cells must be walkable
				var ortho1 = cell + Vector3i(offset.x, 0, 0)
				var ortho2 = cell + Vector3i(0, 0, offset.z)
				
				if terrain.is_walkable_cell(ortho1) and terrain.is_walkable_cell(ortho2):
					neighbors.append({"cell": neighbor, "cost": 14.0})
		
		return neighbors
	
	func _calculate_heuristic(from: Vector3i, to: Vector3i) -> float:
		# Octile distance (allows diagonal movement)
		var dx = abs(to.x - from.x)
		var dy = abs(to.y - from.y) 
		var dz = abs(to.z - from.z)
		
		# For 2D pathfinding on a grid, we ignore Y differences
		var diagonal_moves = min(dx, dz)
		var straight_moves = max(dx, dz) - diagonal_moves
		
		return diagonal_moves * 14.0 + straight_moves * 10.0 + dy * 10.0
	
	func _reconstruct_path(goal: Vector3i) -> Array[Vector3i]:
		var path: Array[Vector3i] = []
		var current = goal
		
		# Reconstruct path by following came_from chain
		while came_from.has(current):
			path.push_front(current)
			current = came_from[current]
		
		return path

## Legacy functions for backward compatibility

static func _h_octile(a: Vector3i, b: Vector3i) -> int:
	var dx: int = abs(a.x - b.x)
	var dz: int = abs(a.z - b.z)
	# Octile distance with 10/14 costs
	return 10 * (dx + dz) + (14 - 20) * min(dx, dz)

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
