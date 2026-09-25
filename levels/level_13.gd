extends LevelData
## Test Level 13 - "Two Sources". Introduces multiple emitters: two
## completely independent single-mirror puzzles must both be solved (one
## rotation each) for the level to complete. See TEST_PLAN.md for the
## verified solution trace.

func _init() -> void:
	level_id = 13
	display_name = "Two Sources"
	grid_width = 5
	grid_height = 5
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(2, 0)),

		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 4)),
	]
