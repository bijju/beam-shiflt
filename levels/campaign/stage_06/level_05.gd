extends LevelData
## Campaign Level 55 — "Sequence Lock". Post-reboot Levels 51-60,
## mid-block checkpoint. A splitter's straight branch chains two
## filters (only the last determines the target color) AND trips a
## switch mid-chain that gates the reflected branch entirely - color
## reasoning and gate dependency layered on the same branch. See
## CAMPAIGN_DESIGN.md section 11i.

func _init() -> void:
	level_id = 5
	display_name = "Sequence Lock"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: the straight branch does double duty - its filter order (GREEN then RED, last wins) sets target A's required color, AND a switch sitting between the two filters is what opens the gate blocking the entire reflected branch. A player who solves the color puzzle without noticing the switch still leaves target B permanently gated. Straight branch (unconditional RIGHT off splitter (1,3)): mirror (2,3) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (2,2) instead - mirror (2,4) flips to BACKSLASH (RIGHT), mirror (3,4) flips to BACKSLASH (DOWN), through filter (3,5) GREEN, mirror (3,6) flips to BACKSLASH (RIGHT), through filter (4,6) RED (overwrites GREEN), through switch (5,6) [g1], mirror (6,6) flips to BACKSLASH (DOWN), into target A (6,7, RED). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), mirror (2,0) flips to BACKSLASH (DOWN), mirror (2,1) flips to BACKSLASH (RIGHT), through gate (4,1) [g1, opened by the straight branch's switch], mirror (5,1) flips to BACKSLASH (DOWN), mirror (5,4) flips to BACKSLASH (RIGHT), into target B (6,4, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,5) instead. INTENTIONAL DECOY: mirror (6,1) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 5)),
		TilePlacement.make_blocker(Vector2i(2, 2)),
		TilePlacement.make_mirror(Vector2i(6, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(3, 5), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 6), GridTypes.BeamColor.RED),
		TilePlacement.make_switch(Vector2i(5, 6), "g1"),
		TilePlacement.make_mirror(Vector2i(6, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 7), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(4, 1), "g1", false),
		TilePlacement.make_mirror(Vector2i(5, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 4), GridTypes.BeamColor.WHITE),
	]
