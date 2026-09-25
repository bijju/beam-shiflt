extends LevelData
## Campaign Level 44 — "Overwatch". DIFFICULTY REWORK PASS 2.
## Two independent emitters share one gate; emitter 2's beam only earns
## its final rotation payoff (three more mirrors) after emitter 1 opens
## the way through.
## See CAMPAIGN_DESIGN.md section 11h (Pass 2).

func _init() -> void:
	level_id = 4
	display_name = "Overwatch"
	stage = "Filters"
	developer_notes = "DESIGN INTENT: emitter 1's beam has no target of its own - its only job is to trip switch (2,2) via mirrors (1,1) and (1,2). Emitter 2's beam is gated at (3,4) until that happens, then needs three more correctly-placed mirrors beyond the gate to actually reach the target - the gate opening isn't the finish line. Emitter 1 chain: mirror (1,1) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,0) instead - mirror (1,2) flips to BACKSLASH (RIGHT), into switch (2,2). Emitter 2 chain: mirror (1,3) flips to BACKSLASH (DOWN), mirror (1,4) flips to BACKSLASH (RIGHT), through the now-open gate (3,4), mirror (4,4) flips to BACKSLASH (DOWN), mirror (4,5) flips to BACKSLASH (RIGHT), mirror (5,5) flips to BACKSLASH (DOWN), into target A (5,6, WHITE)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 0)),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(2, 2), "g1"),
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(3, 4), "g1", false),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 6), GridTypes.BeamColor.WHITE),
	]
