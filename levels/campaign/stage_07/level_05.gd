extends LevelData
## Campaign Level 65 — "Convergence Point". Post-60 Levels 61-70,
## MASTER-ENTRY CHECKPOINT. The straight branch's beam continues past
## its own required target and trips a switch that gates the entire
## reflected branch - solving target A is not the end of that branch's
## job. See CAMPAIGN_DESIGN.md section 11j.

func _init() -> void:
	level_id = 5
	display_name = "Convergence Point"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: the beam continues past target A (per LaserSystem's documented behavior) and that continuation is what trips the switch gating the ENTIRE reflected branch - a player who stops reasoning once target A lights up will never realize why target B stays dark. Straight branch (unconditional RIGHT off splitter (2,6)): mirror (3,6) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,3) instead - mirror (3,8) flips to BACKSLASH (RIGHT), mirror (4,8) flips to BACKSLASH (DOWN), mirror (4,9) flips to BACKSLASH (RIGHT), into target A (6,9, WHITE), continues RIGHT past it into switch (7,9) [g1], continues off the edge. Reflected branch: splitter flips to SLASH (UP), mirror (2,3) flips to BACKSLASH (LEFT), mirror (1,3) flips to BACKSLASH (UP), mirror (1,0) flips to SLASH (RIGHT), through gate (4,0) [g1, opened by the straight branch's post-target continuation], mirror (5,0) flips to BACKSLASH (DOWN), mirror (5,2) flips to BACKSLASH (RIGHT), mirror (6,2) flips to BACKSLASH (DOWN), mirror (6,4) flips to BACKSLASH (RIGHT), into target B (7,4, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,9) instead. INTENTIONAL DECOY: mirror (8,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 12
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 6), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(2, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 9)),
		TilePlacement.make_blocker(Vector2i(3, 3)),
		TilePlacement.make_mirror(Vector2i(8, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 9), GridTypes.BeamColor.WHITE),
		TilePlacement.make_switch(Vector2i(7, 9), "g1"),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(4, 0), "g1", false),
		TilePlacement.make_mirror(Vector2i(5, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 4), GridTypes.BeamColor.WHITE),
	]
