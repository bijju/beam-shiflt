extends LevelData
## Campaign Level 73 — "Locked Splitter". Post-70 Levels 71-80, MASTER
## TIER. A single splitter's two branches gate EACH OTHER (mutual
## switch/gate dependency, like Level 51 but deepened with a 2-filter-
## order chain on each branch). See CAMPAIGN_DESIGN.md section 11k.

func _init() -> void:
	level_id = 3
	display_name = "Locked Splitter"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: each branch's own switch opens the OTHER branch's gate - resolved automatically across two passes - AND each branch independently runs a 2-filter-order chain (last filter wins) before its own gate. Straight branch (unconditional RIGHT off splitter (1,3)): mirror (2,3) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (2,1) instead - mirror (2,4) flips to BACKSLASH (RIGHT), mirror (3,4) flips to BACKSLASH (DOWN), filter (3,6) RED, mirror (3,7) flips to BACKSLASH (RIGHT), filter (4,7) BLUE (overwrites RED), switch (5,7) [g1], through gate (6,7) [g2, opened by the reflected branch's switch], mirror (7,7) flips to BACKSLASH (DOWN) -> target A (7,8, BLUE). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), filter (2,0) GREEN, mirror (3,0) flips to BACKSLASH (DOWN), mirror (3,1) flips to BACKSLASH (RIGHT), filter (4,1) RED (overwrites GREEN), mirror (5,1) flips to BACKSLASH (DOWN), switch (5,2) [g2], through gate (5,3) [g1, opened by the straight branch's switch], mirror (5,4) flips to BACKSLASH (RIGHT) -> target B (6,4, RED). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,6) instead. INTENTIONAL DECOY: mirror (8,9) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 6)),
		TilePlacement.make_blocker(Vector2i(2, 1)),
		TilePlacement.make_mirror(Vector2i(8, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(3, 6), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_switch(Vector2i(5, 7), "g1"),
		TilePlacement.make_gate(Vector2i(6, 7), "g2", false),
		TilePlacement.make_mirror(Vector2i(7, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 8), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(2, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 1), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(5, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(5, 2), "g2"),
		TilePlacement.make_gate(Vector2i(5, 3), "g1", false),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 4), GridTypes.BeamColor.RED),
	]
