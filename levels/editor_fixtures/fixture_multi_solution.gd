extends LevelData
## EDITOR FIXTURE - development/validator testing only. Two entirely
## independent one-mirror chains both feed the SAME single required
## target from different directions, so either chain alone (1 rotation,
## leaving the other chain's mirror in its wrong state) solves the
## level. LevelSolver must report shortest_solution_count == 2 at
## optimal_moves == 1.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Multiple Shortest Solutions"
	grid_width = 5
	grid_height = 5
	optimal_moves = 1
	tiles = [
		# Chain A: needs BACKSLASH (RIGHT->DOWN) to reach the target from above.
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),

		# Chain B: needs SLASH (DOWN->LEFT) to reach the target from the right.
		TilePlacement.make_emitter(Vector2i(4, 2), GridTypes.Direction.DOWN),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.BACKSLASH),

		TilePlacement.make_target(Vector2i(2, 4)),
	]
