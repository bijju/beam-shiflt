extends LevelData
## Test Level 10 - "Through the Portal". Introduces paired portals: after
## one mirror rotation the beam travels down into portal A and emerges
## from portal B still heading the same direction, reaching a target that
## has no direct line of sight from the emitter. See TEST_PLAN.md for the
## verified solution trace.

func _init() -> void:
	level_id = 10
	display_name = "Through the Portal"
	grid_width = 5
	grid_height = 5
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(2, 2), "P"),
		TilePlacement.make_portal(Vector2i(4, 2), "P"),
		TilePlacement.make_target(Vector2i(4, 4)),
	]
