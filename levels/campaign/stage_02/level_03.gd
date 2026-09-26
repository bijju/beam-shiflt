extends LevelData
## Campaign Level 13 (Stage 2 #3) — "Fork Point". Two genuinely plausible
## multi-cell continuations from one mirror - only one actually reaches
## the target. See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (3).

func _init() -> void:
	level_id = 3
	display_name = "Fork Point"
	stage = "Reflection"
	developer_notes = "False-route design: Mirror A's wrong (SLASH) orientation leads to a real mirror that looks like a legitimate continuation (not just an instant off-grid exit) but ultimately exits the board without reaching the target. The correct (BACKSLASH) branch takes 2 more real turns to reach the target. Verified the false branch cannot accidentally reach the target under any orientation of that mirror."
	is_campaign_level = true
	grid_width = 5
	grid_height = 6
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 3)),
	]
