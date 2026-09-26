extends LevelData
## Campaign Level 18 (Stage 2 #8) — "Echo Path". A five-mirror route
## that visits all four edges of the board before converging near the
## center - dense-looking, but every piece is load-bearing (no decoys).
## See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x7 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (5).

func _init() -> void:
	level_id = 8
	display_name = "Echo Path"
	stage = "Reflection"
	developer_notes = "A 'spiral' route: right along the top edge, down the right edge, left along the bottom edge (into a fixed mirror), up the left edge, then two more turns to converge near the center. Five rotatable mirrors (A,B,D,E,F) all start wrong, plus one fixed mirror (C) as a mandatory waypoint - not a decoy, just a piece the player never rotates. No blocker this level; the length and edge-touring shape are the difficulty, not extra mechanics."
	is_campaign_level = true
	grid_width = 5
	grid_height = 7
	optimal_moves = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(0, 6), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(0, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(1, 4)),
	]
