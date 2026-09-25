extends LevelData
## Campaign Level 17 (Stage 2 #7) — "Backtrack". Second backward-
## reasoning level: a fixed mirror beside the target demands a specific
## approach direction, a blocker punishes the wrong fork earlier in the
## chain, and the route is the longest real chain yet (4 rotatable + 1
## fixed). See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x7 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (4).

func _init() -> void:
	level_id = 7
	display_name = "Backtrack"
	stage = "Reflection"
	developer_notes = "BACKWARD REASONING: the fixed mirror at (3,3) only sends the beam right into the target when hit traveling DOWN (BACKSLASH: DOWN->RIGHT) - trace backward from there to find the required route. FALSE ROUTE: Mirror C's wrong (BACKSLASH) orientation sends the beam directly into the blocker at (1,0), a concrete guard against the natural-looking 'just go up then left' guess. Four rotatable mirrors (Z, B, C, D), all starting wrong."
	is_campaign_level = true
	grid_width = 5
	grid_height = 7
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.DOWN),
		TilePlacement.make_mirror(Vector2i(0, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_blocker(Vector2i(1, 0)),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 3), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(4, 3)),
	]
