extends LevelData
## Campaign Level 12 (Stage 2 #2) — "Dead End". Blocker-focused: the
## fork mirror's wrong orientation sends the beam straight into a
## blocker, teaching that the shorter-looking branch can be a trap. See
## CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (3).

func _init() -> void:
	level_id = 2
	display_name = "Dead End"
	stage = "Reflection"
	developer_notes = "Teaches: Mirror A's wrong (SLASH) orientation sends the beam directly into the blocker two cells away - a real, punishing guard, not a silent off-grid exit. Correct route detours through B and C instead."
	is_campaign_level = true
	grid_width = 5
	grid_height = 6
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_blocker(Vector2i(2, 0)),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 2)),
	]
