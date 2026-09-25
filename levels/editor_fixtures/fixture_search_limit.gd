extends LevelData
## EDITOR FIXTURE - development/validator testing only. A normal
## 1-rotation solvable core plus 8 decorative rotatable mirrors placed
## entirely off the beam's path (they never affect solvability - just
## inflate the state space to 2^9 = 512). LevelSolver.analyze() with its
## default limit (65536) solves this instantly and correctly; calling it
## with an artificially small max_states (e.g. 5) demonstrates
## status="UNKNOWN" rather than a false "UNSOLVABLE" - the search never
## actually proved there's no solution, it just ran out of budget.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Search Limit Demonstration"
	grid_width = 8
	grid_height = 8
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(2, 7)),

		# Decorative filler - never touched by any beam.
		TilePlacement.make_mirror(Vector2i(5, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(7, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(7, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 2), GridTypes.MirrorOrientation.SLASH),
	]
