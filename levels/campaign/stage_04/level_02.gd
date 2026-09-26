extends LevelData
## Campaign Level 32 — "Gauntlet". DIFFICULTY REWORK PASS 2.
## Two independent emitters share one gate: emitter 1's entire job is to
## reach a switch through its own 2-mirror chain; emitter 2's beam is
## physically blocked until that happens, then has to be routed through
## its own longer chain to the target.
## See CAMPAIGN_DESIGN.md section 11g (Pass 2).

func _init() -> void:
	level_id = 2
	display_name = "Gauntlet"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: emitter 1's beam has no target of its own - its only job is to trip switch (2,2) via mirrors (1,1) and (1,2). Emitter 2's beam is gated at (3,4) until that happens, then has to be routed through its own 3-mirror chain to the target. Emitter 1 chain: mirror (1,1) flips to BACKSLASH (DOWN), mirror (1,2) flips to BACKSLASH (RIGHT), into switch (2,2). If mirror (1,1) is left at its authored SLASH, the beam runs UP into the hazard at (1,0) instead and the switch is never reached. Emitter 2 chain: mirror (1,3) flips to BACKSLASH (DOWN), mirror (1,4) flips to BACKSLASH (RIGHT), through the now-open gate (3,4), mirror (4,4) flips to BACKSLASH (DOWN), mirror (4,5) flips to BACKSLASH (RIGHT), mirror (5,5) flips to BACKSLASH (DOWN), into target A (5,6, WHITE). The two emitters never share a tile except the gate's dependency - solving one branch alone never activates anything."
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
