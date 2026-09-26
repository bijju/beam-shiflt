extends LevelData
## Campaign Level 29 — "Stalemate". DIFFICULTY REWORK PASS 2.
## Splitter/switch/gate dependency: the reflected branch's ONLY job is to
## reach a switch through a backward-reasoning fixed mirror; the straight
## branch is physically gated until that happens, then relays through two
## more mirrors to its target.
## See CAMPAIGN_DESIGN.md section 11f (Pass 2).

func _init() -> void:
	level_id = 9
	display_name = "Stalemate"
	stage = "Split"
	developer_notes = "DESIGN INTENT: the gate at (4,3) blocks the splitter's straight branch until the reflected branch's own detour trips the switch at (3,1) - and the fixed mirror at (3,0) means the player has to reason backward (target color aside, this is pure routing) to see that the switch is only reached if the beam arrives at (3,0) moving RIGHT. Reflected branch: splitter flips to SLASH (UP), mirror (1,2) flips to SLASH (RIGHT), mirror (2,2) flips to SLASH (UP), mirror (2,0) flips to SLASH (RIGHT), into fixed mirror (3,0, BACKSLASH, RIGHT->DOWN) -> switch (3,1) -> exits harmlessly off the bottom edge. Straight branch (unconditional RIGHT off splitter (1,3)): passes the now-open gate (4,3) -> mirror (5,3) flips to BACKSLASH (DOWN) -> mirror (5,4) flips to SLASH (LEFT) -> mirror (4,4) flips to SLASH (DOWN) -> target A (4,6, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,5) instead and the gate never opens. INTENTIONAL DECOY: mirror (5,1) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 5)),
		TilePlacement.make_mirror(Vector2i(5, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(4, 3), "g1", false),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 6), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_switch(Vector2i(3, 1), "g1"),
	]
