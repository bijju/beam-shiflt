extends LevelData
## Test Level 12 - "Danger Zone". Introduces the hazard: leaving the first
## mirror unrotated sends the beam straight into a hazard (level fails to
## solve while hazard_hit is true, but play is not interrupted - see
## ARCHITECTURE.md). The player must route around it with two rotations.
## See TEST_PLAN.md for the verified solution trace.

func _init() -> void:
	level_id = 12
	display_name = "Danger Zone"
	grid_width = 5
	grid_height = 5
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(2, 0)),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 3)),
	]
