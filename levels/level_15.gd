extends LevelData
## Test Level 15 - "All Systems". Milestone 2 challenge level, combining
## switch/gate, hazard, portal, and multiple emitters: two independent
## chains, each needing one mirror rotation. Chain A routes a beam over a
## switch that opens a gate guarding its target. Chain B's unrotated
## mirror sends its beam into a hazard; rotated, it instead travels
## through a portal pair to reach its own target. See TEST_PLAN.md for
## the verified solution trace.

func _init() -> void:
	level_id = 15
	display_name = "All Systems"
	grid_width = 6
	grid_height = 6
	optimal_moves = 2
	tiles = [
		# Chain A: switch + gate.
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(2, 2), "G"),
		TilePlacement.make_gate(Vector2i(2, 4), "G", false),
		TilePlacement.make_target(Vector2i(2, 5)),

		# Chain B: hazard avoidance + portal.
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(4, 1)),
		TilePlacement.make_portal(Vector2i(4, 5), "P"),
		TilePlacement.make_portal(Vector2i(1, 1), "P"),
		TilePlacement.make_target(Vector2i(1, 5)),
	]
