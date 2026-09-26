extends LevelData
## Campaign Level 51 — "Interlock". Post-reboot Levels 51-60 (internal
## folder stage_06), continuing directly from the Levels 46-50
## difficulty region - no mechanic-teaching reset. See CAMPAIGN_DESIGN.md
## section 11i.
##
## A splitter feeds two switch/gate pairs that gate EACH OTHER: each
## branch's own switch is what lets the OTHER branch's beam through its
## gate. Neither branch can be solved in isolation - simulate_until_stable's
## multi-pass resolution settles both simultaneously once the whole board
## is wired correctly.

func _init() -> void:
	level_id = 1
	display_name = "Interlock"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: mutual switch/gate dependency - branch A's switch (g1) opens the gate blocking branch B, and branch B's switch (g2) opens the gate blocking branch A, resolved automatically once both routes are wired (pass 1: both switches trip, both gates still closed; pass 2: both gates open, both beams reach their targets). Straight branch (unconditional RIGHT off splitter (2,2)): mirror (3,2) flips to BACKSLASH (DOWN), mirror (3,4) flips to BACKSLASH (RIGHT), mirror (4,4) flips to BACKSLASH (DOWN), into switch (4,5) [g1], through gate (4,6) [g2, opened by the reflected branch's switch], mirror (4,7) flips to SLASH (LEFT), into target A (1,7, WHITE). Reflected branch: splitter flips to SLASH (UP), mirror (2,0) flips to SLASH (RIGHT), mirror (3,0) flips to BACKSLASH (DOWN), mirror (3,1) flips to BACKSLASH (RIGHT), into switch (4,1) [g2], through gate (5,1) [g1, opened by the straight branch's switch], mirror (6,1) flips to BACKSLASH (DOWN), into target B (6,2, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,5) instead - a real punishment, not a geometry miss. POST-TARGET HAZARD AVOIDANCE (not a decoy - solver-confirmed load-bearing): the beam continues past target B, DOWN through (6,4) into mirror (6,5), which must flip to BACKSLASH (RIGHT, off the board) - left at its authored SLASH it deflects LEFT straight into the SAME hazard at (2,5), so a correctly-solved board still fails if this one piece is left untouched. This was originally authored as an intentional decoy and only became load-bearing once the solver traced the beam's full continuation past target B - see CAMPAIGN_DESIGN.md section 8's standing warning about this exact trap."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 10
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 5)),
		TilePlacement.make_mirror(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(4, 5), "g1"),
		TilePlacement.make_gate(Vector2i(4, 6), "g2", false),
		TilePlacement.make_mirror(Vector2i(4, 7), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(1, 7), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(4, 1), "g2"),
		TilePlacement.make_gate(Vector2i(5, 1), "g1", false),
		TilePlacement.make_mirror(Vector2i(6, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 2), GridTypes.BeamColor.WHITE),
	]
