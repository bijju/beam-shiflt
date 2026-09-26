extends LevelData
## Campaign Level 19 (Stage 2 #9) — "Interference". Pre-finale challenge:
## a five-mirror route with two decoys planted near the action. See
## CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x7 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (5).

func _init() -> void:
	level_id = 9
	display_name = "Interference"
	stage = "Reflection"
	developer_notes = "INTENTIONAL DECOYS: mirrors at (2,2) and (3,5) - both mid-board, near the real route's turns, but never touched by the solved beam (verified against the traced path). Real route: 5 rotatable mirrors (A,B,C,D,E) tracing all four edges of the board before turning inward to the target, all starting wrong. The hardest level before the Stage 2 finale."
	is_campaign_level = true
	grid_width = 5
	grid_height = 7
	optimal_moves = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(1, 5)),
	]
