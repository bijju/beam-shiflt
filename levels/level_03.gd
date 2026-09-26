extends LevelData
## Test Level 3 - "Obstruction". Introduces the blocker: leaving the first
## mirror unrotated sends the beam straight into a blocker, demonstrating
## the mechanic before the player routes around it. See TEST_PLAN.md.

func _init() -> void:
	level_id = 3
	display_name = "Obstruction"
	grid_width = 5
	grid_height = 5
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_blocker(Vector2i(2, 0)),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 3)),
	]
