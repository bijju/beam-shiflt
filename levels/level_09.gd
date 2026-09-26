extends LevelData
## Test Level 9 - "Recolor". Introduces the color filter: the default
## (WHITE) beam becomes RED after passing through the filter, which is
## what lets it activate a RED-required target. See TEST_PLAN.md for the
## verified solution trace.

func _init() -> void:
	level_id = 9
	display_name = "Recolor"
	grid_width = 5
	grid_height = 5
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(2, 1), GridTypes.BeamColor.RED),
		TilePlacement.make_target(Vector2i(2, 0), GridTypes.BeamColor.RED),
	]
