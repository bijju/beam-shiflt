extends LevelData
## Test Level 8 - "True Color". Introduces colored emitters/targets: a
## GREEN beam only activates a GREEN-required target. See TEST_PLAN.md
## for the verified solution trace.

func _init() -> void:
	level_id = 8
	display_name = "True Color"
	grid_width = 5
	grid_height = 5
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(2, 0), GridTypes.BeamColor.GREEN),
	]
