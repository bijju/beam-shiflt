extends LevelData
## Test Level 1 - "First Light". Teaches basic reflection: one mirror,
## one rotation needed. See TEST_PLAN.md for the verified solution trace.

func _init() -> void:
	level_id = 1
	display_name = "First Light"
	grid_width = 5
	grid_height = 5
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(2, 0)),
	]
