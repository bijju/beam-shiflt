extends LevelData
## Campaign Level 7 — "Deception". Introduces the stage's first genuine
## decoy piece: a rotatable mirror that the beam never actually reaches in
## any solution, placed near the middle of the board where a player
## scanning for "unused" pieces might assume it matters. See
## CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x7 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (3).
## The decoy mirror is now at (3,4) - still never on the beam's path.

func _init() -> void:
	level_id = 7
	display_name = "Deception"
	stage = "First Light"
	developer_notes = "INTENTIONAL DECOY: the mirror at (3,4) is never on the beam's path in the solved state - its orientation is irrelevant. Placed mid-board, one column right of the real route, so it looks plausible without ever mattering. Real route needs 3 mirrors (A, B, C) all starting wrong."
	is_campaign_level = true
	grid_width = 5
	grid_height = 7
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(4, 0), GridTypes.Direction.DOWN),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(1, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(3, 6)),
	]
