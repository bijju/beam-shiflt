extends LevelData
## Test Level 7 - "Split Path". Introduces the splitter: the straight
## branch always reaches one target regardless of orientation, while the
## reflected branch needs one rotation to reach the second target - see
## TEST_PLAN.md for the verified solution trace.

func _init() -> void:
	level_id = 7
	display_name = "Split Path"
	grid_width = 5
	grid_height = 5
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_splitter(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 2)),
		TilePlacement.make_target(Vector2i(2, 0)),
	]
