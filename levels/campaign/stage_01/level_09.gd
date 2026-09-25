extends LevelData
## Campaign Level 9 — "Junction". Combines every Stage 1 mechanic at
## once: a fixed mirror, three rotatable mirrors, a blocker guarding a
## wrong fork, and a decoy near the trap. See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x7 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (3).

func _init() -> void:
	level_id = 9
	display_name = "Junction"
	stage = "First Light"
	developer_notes = "INTENTIONAL DECOY: mirror at (0,4), left edge, never on the beam path (note: LaserSystem lets a beam continue past an activated target, so the decoy was deliberately kept off the target's own row to avoid the beam clipping it after solving). Placed near the blocker's column so it looks related to avoiding the trap. Combines: 1 fixed mirror (start of route), 3 rotatable mirrors (R1/R2/R3, all start wrong), 1 blocker guarding R1's wrong fork."
	is_campaign_level = true
	grid_width = 5
	grid_height = 7
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_blocker(Vector2i(0, 2)),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(0, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(2, 6)),
	]
