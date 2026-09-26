extends LevelData
## Test Level 4 - "Fixed Point". Introduces the fixed vs. rotatable mirror
## distinction: the first mirror cannot be rotated and must be planned
## around, while two rotatable mirrors need one rotation each.
## See TEST_PLAN.md for the verified solution trace.

func _init() -> void:
	level_id = 4
	display_name = "Fixed Point"
	grid_width = 5
	grid_height = 5
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_mirror(Vector2i(2, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 3)),
	]
