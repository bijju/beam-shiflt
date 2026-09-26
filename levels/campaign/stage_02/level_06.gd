extends LevelData
## Campaign Level 16 (Stage 2 #6) — "Cascade". Multi-step dependency:
## Mirror A's correct orientation only makes sense once the full 4-bounce
## downstream route (through B, E, F) is understood - its wrong choice
## simply exits the board with no visible clue why it's wrong. See
## CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x7 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (4).

func _init() -> void:
	level_id = 6
	display_name = "Cascade"
	stage = "Reflection"
	developer_notes = "MULTI-STEP DEPENDENCY: Mirror A's two orientations both look like reasonable early choices (one continues down, one continues up) - only by tracing the down branch all the way through B, E, and F does it become clear that's the one reaching the target. All four real mirrors start wrong; no shortcut exists."
	is_campaign_level = true
	grid_width = 5
	grid_height = 7
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 0)),
	]
