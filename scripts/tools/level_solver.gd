class_name LevelSolver
extends RefCounted
## Development-only puzzle solver. Determines whether a level is solvable
## by rotating its player-controllable pieces (rotatable mirrors and
## splitters only - never fixed mirrors, emitter placement, target
## requirements, filters, portals, gates, or hazards), and if so, the
## minimum number of moves required.
##
## Uses the REAL LaserSystem to evaluate every candidate board state -
## this never re-implements beam logic. See ARCHITECTURE.md ("Level
## editor / solver architecture") and DECISIONS.md for the algorithm
## choice and safety-limit reasoning.
##
## This script is development tooling only. Nothing in the shipped
## gameplay path (game.gd, grid_manager.gd) calls into it.

## Exhaustive for any level with up to 16 rotatable pieces (2^16 = 65536
## states); a hard backstop beyond that so the editor never hangs. See
## DECISIONS.md ("Solver search-limit strategy") for why this default
## was chosen.
const DEFAULT_MAX_STATES := 65536


## Result dictionary shape:
## {
##   "status": "SOLVABLE" | "UNSOLVABLE" | "UNKNOWN",
##   "trivial": bool,                # already solved with zero moves
##   "optimal_moves": int,           # -1 if not found
##   "shortest_solution_count": int, # distinct states at the optimal depth
##   "states_explored": int,
##   "elapsed_ms": int,
##   "solution_path": Array[{ "position": Vector2i, "from": GridTypes.MirrorOrientation, "to": GridTypes.MirrorOrientation }],
##   "possible_decoys": Array[Vector2i], # rotatable positions whose orientation
##                                        # didn't matter in at least one found shortest solution
## }
static func analyze(level_data: LevelData, max_states: int = DEFAULT_MAX_STATES) -> Dictionary:
	var start_time := Time.get_ticks_msec()

	var rotatable: Array[TilePlacement] = level_data.get_rotatable_tiles()
	var n := rotatable.size()

	# Fixed (non-rotatable) mirrors/splitters keep their authored
	# orientation for every candidate state - only rotatable ones vary.
	var base_orientations: Dictionary = level_data.get_initial_tile_orientations()
	for t in rotatable:
		base_orientations.erase(t.position) # will be set per-candidate-state below

	if n > 30:
		# 2^31 would overflow a signed 32-bit bitmask range some GDScript
		# int paths assume; this is far beyond any plausible hand-authored
		# level (and DEFAULT_MAX_STATES would truncate the search long
		# before reaching this many pieces anyway), so it's a defensive
		# cap, not a real design constraint.
		return _make_result("UNKNOWN", false, -1, 0, 0, start_time, [], [])

	var initial_bits := 0
	for i in range(n):
		if rotatable[i].mirror_orientation == GridTypes.MirrorOrientation.BACKSLASH:
			initial_bits |= (1 << i)

	var visited := {initial_bits: true}
	var parent := {} # bits -> {"from": int, "flip": int}
	var frontier: Array[int] = [initial_bits]
	var states_explored := 0
	var found_depth := -1
	var solutions: Array[int] = []
	var trivial := false
	var limit_hit := false

	var depth := 0
	while frontier.size() > 0:
		var next_frontier: Array[int] = []

		for bits in frontier:
			if states_explored >= max_states:
				limit_hit = true
				break
			states_explored += 1

			var orientations := base_orientations.duplicate()
			for i in range(n):
				var o = GridTypes.MirrorOrientation.BACKSLASH if (bits & (1 << i)) != 0 else GridTypes.MirrorOrientation.SLASH
				orientations[rotatable[i].position] = o

			var result := LaserSystem.simulate_until_stable(level_data, orientations)
			if result["solved"]:
				solutions.append(bits)
				if depth == 0:
					trivial = true
				continue # a solved state is terminal - don't expand it further

			for i in range(n):
				var neighbor: int = bits ^ (1 << i)
				if not visited.has(neighbor):
					visited[neighbor] = true
					parent[neighbor] = {"from": bits, "flip": i}
					next_frontier.append(neighbor)

		if limit_hit:
			break
		if solutions.size() > 0:
			found_depth = depth
			break # every solution at this depth has been found; deeper states can't be shorter

		frontier = next_frontier
		depth += 1

	var status: String
	if found_depth != -1:
		status = "SOLVABLE"
	elif limit_hit:
		status = "UNKNOWN"
	else:
		status = "UNSOLVABLE" # frontier exhausted with no solution anywhere in the reachable state space

	var solution_path: Array = []
	var possible_decoys: Array = []
	if status == "SOLVABLE":
		solution_path = _reconstruct_path(solutions[0], parent, rotatable)
		possible_decoys = _find_possible_decoys(level_data, base_orientations, rotatable, solutions)

	return _make_result(status, trivial, found_depth, solutions.size(), states_explored, start_time, solution_path, possible_decoys)


static func _make_result(status: String, trivial: bool, optimal_moves: int, shortest_solution_count: int, states_explored: int, start_time: int, solution_path: Array, possible_decoys: Array) -> Dictionary:
	return {
		"status": status,
		"trivial": trivial,
		"optimal_moves": optimal_moves,
		"shortest_solution_count": shortest_solution_count,
		"states_explored": states_explored,
		"elapsed_ms": Time.get_ticks_msec() - start_time,
		"solution_path": solution_path,
		"possible_decoys": possible_decoys,
	}


static func _reconstruct_path(solved_bits: int, parent: Dictionary, rotatable: Array[TilePlacement]) -> Array:
	var steps: Array = []
	var bits := solved_bits
	while parent.has(bits):
		var p: Dictionary = parent[bits]
		var flip_index: int = p["flip"]
		var from_bits: int = p["from"]
		var was_backslash: bool = (from_bits & (1 << flip_index)) != 0
		steps.push_front({
			"position": rotatable[flip_index].position,
			"from": GridTypes.MirrorOrientation.BACKSLASH if was_backslash else GridTypes.MirrorOrientation.SLASH,
			"to": GridTypes.MirrorOrientation.SLASH if was_backslash else GridTypes.MirrorOrientation.BACKSLASH,
		})
		bits = from_bits
	return steps


## For each found shortest solution, check whether toggling any single
## rotatable piece (independently) still leaves the level solved. If so,
## that piece's orientation didn't matter for that solution - a candidate
## decoy. Informational only; nothing is ever auto-removed. Bounded cost:
## shortest_solution_count * n extra simulate_until_stable() calls.
static func _find_possible_decoys(level_data: LevelData, base_orientations: Dictionary, rotatable: Array[TilePlacement], solutions: Array[int]) -> Array:
	var n := rotatable.size()
	var decoys := {}

	for solved_bits in solutions:
		for i in range(n):
			var toggled: int = solved_bits ^ (1 << i)
			var orientations := base_orientations.duplicate()
			for j in range(n):
				var o = GridTypes.MirrorOrientation.BACKSLASH if (toggled & (1 << j)) != 0 else GridTypes.MirrorOrientation.SLASH
				orientations[rotatable[j].position] = o
			var result := LaserSystem.simulate_until_stable(level_data, orientations)
			if result["solved"]:
				decoys[rotatable[i].position] = true

	return decoys.keys()
