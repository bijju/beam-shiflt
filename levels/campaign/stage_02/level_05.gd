extends LevelData
## Campaign Level 15 (Stage 2 #5) — "Mirage". Decoy-focused: one
## convincing decoy mirror sits right beside the real path's final two
## turns, never actually touched by the solved beam. See
## CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x7 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (4).

func _init() -> void:
	level_id = 5
	display_name = "Mirage"
	stage = "Reflection"
	developer_notes = "INTENTIONAL DECOY: mirror at (4,3), directly adjacent to the real path's D/E turn (3,3)->(3,6)->(4,6) - a player eyeing that corner might assume it's a shortcut, but the beam never reaches it (verified against the solved path). Real route: 4 rotatable mirrors (A,B,D,E), all starting wrong."
	is_campaign_level = true
	grid_width = 5
	grid_height = 7
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 6)),
	]
