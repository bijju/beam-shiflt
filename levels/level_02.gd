extends LevelData
## Test Level 2 - "Reflection". Requires two meaningful mirror rotations
## in sequence. See TEST_PLAN.md for the verified solution trace.

func _init() -> void:
	level_id = 2
	display_name = "Reflection"
	grid_width = 5
	grid_height = 5
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 3)),
	]
