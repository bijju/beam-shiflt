extends LevelData
## Campaign Level 10 — "Breakthrough". Stage 1 finale: a five-mirror
## route (one fixed, four rotatable) winding right/down/right/down/left/
## up across the whole board, with a blocker guarding one wrong fork and
## two decoys planted near the real turns. See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x7 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (4).

func _init() -> void:
	level_id = 10
	display_name = "Breakthrough"
	stage = "First Light"
	developer_notes = "INTENTIONAL DECOYS: mirrors at (0,5) and (3,2) - both left off the beam's actual route (verified against the solved path, including its continuation after the target). Combines every Stage 1 mechanic: 1 fixed mirror, 4 rotatable mirrors (all start wrong - full route must be planned before the first tap), 1 blocker guarding R2's wrong fork, 2 decoys. Deliberately the stage's longest, most winding route."
	is_campaign_level = true
	grid_width = 5
	grid_height = 7
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_blocker(Vector2i(4, 0)),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(1, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(0, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(1, 2)),
	]
