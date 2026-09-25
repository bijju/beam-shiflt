extends LevelData
## Test Level 11 - "Switch and Gate". Introduces switches/gates: one
## mirror rotation routes the beam over a switch and into a closed gate;
## the gate opens automatically on the next simulation pass (see
## ARCHITECTURE.md "Switch/gate simulation strategy") and the same beam
## then reaches the target. See TEST_PLAN.md for the verified trace.

func _init() -> void:
	level_id = 11
	display_name = "Switch and Gate"
	grid_width = 5
	grid_height = 6
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(2, 2), "G"),
		TilePlacement.make_gate(Vector2i(2, 4), "G", false),
		TilePlacement.make_target(Vector2i(2, 5)),
	]
