extends LevelData
## Test Level 14 - "Convergence". Combines splitter + colored beam +
## filter + multiple targets: the straight branch always reaches a
## neutral target, while the reflected branch needs one rotation to reach
## a filter that recolors it to match the second, color-required target.
## See TEST_PLAN.md for the verified solution trace.

func _init() -> void:
	level_id = 14
	display_name = "Convergence"
	grid_width = 5
	grid_height = 5
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.BLUE),
		TilePlacement.make_splitter(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 2)),
		TilePlacement.make_filter(Vector2i(2, 3), GridTypes.BeamColor.RED),
		TilePlacement.make_target(Vector2i(2, 4), GridTypes.BeamColor.RED),
	]
