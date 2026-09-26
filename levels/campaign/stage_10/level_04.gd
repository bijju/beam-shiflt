extends LevelData
## Campaign Level 94 — "Traced Colors". FINAL CAMPAIGN BLOCK
## (Levels 91-100), EXTREME TIER. Built by extending Level 83's already-
## validated splitter/portal/third-emitter geometry: a filter is added
## to EACH branch at a cell already confirmed to be pure single-beam
## transit, giving both branches real color-order reasoning on top of
## the existing gate/relay dependency, while the geometry itself stays
## byte-for-byte proven. See CAMPAIGN_DESIGN.md section 11m.

func _init() -> void:
	level_id = 4
	display_name = "Traced Colors"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical splitter/shared-mirror/third-emitter core to Level 83 - but the straight branch now carries a filter (4,9) RED between the third-emitter's gate and the switch, and the reflected branch carries a filter (6,2) BLUE between two of its own mirrors (overwriting the earlier GREEN) - both inserted at cells independently confirmed to be pure single-beam transit points for exactly one beam each, causing zero interference with the existing gate/relay structure. Straight branch (unconditional RIGHT off splitter (2,5)): mirror (3,5) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,2) instead - mirror (3,6) flips to BACKSLASH (RIGHT), into portal (4,6)/pair A -> exits (1,9) still moving RIGHT -> through gate (2,9) [g3], filter (4,9) RED, switch (7,9) [g1] -> mirror (8,9) flips to BACKSLASH (DOWN), into the shared mirror -> RIGHT -> target A (9,10, RED). Reflected branch: splitter flips to SLASH (UP), mirror (2,0) flips to SLASH (RIGHT), filter (3,0) GREEN, through gate (4,0) [g1, opened by the straight branch's switch], mirror (5,0) flips to BACKSLASH (DOWN), mirror (5,1) flips to BACKSLASH (RIGHT), mirror (6,1) flips to BACKSLASH (DOWN), filter (6,2) BLUE (overwrites GREEN), mirror (6,4) flips to BACKSLASH (RIGHT), mirror (7,4) flips to BACKSLASH (DOWN) (passing harmlessly back through switch (7,9) along the way), mirror (7,10) flips to BACKSLASH (RIGHT), into the shared mirror from the west -> DOWN -> target B (8,11, BLUE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,7) instead. Third emitter (fires RIGHT from (0,11), identical to Level 83): switch (1,11) [g3] trips as soon as the beam reaches it - mirror (2,11) is a genuine decoy (solver-confirmed). INTENTIONAL DECOYS: mirror (9,0) and mirror (2,11) are never load-bearing in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 12
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(2, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 7)),
		TilePlacement.make_blocker(Vector2i(3, 2)),
		TilePlacement.make_mirror(Vector2i(9, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(4, 6), "A"),
		TilePlacement.make_portal(Vector2i(1, 9), "A"),
		TilePlacement.make_gate(Vector2i(2, 9), "g3", false),
		TilePlacement.make_filter(Vector2i(4, 9), GridTypes.BeamColor.RED),
		TilePlacement.make_switch(Vector2i(7, 9), "g1"),
		TilePlacement.make_mirror(Vector2i(8, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(8, 10), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(9, 10), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(3, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_gate(Vector2i(4, 0), "g1", false),
		TilePlacement.make_mirror(Vector2i(5, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(6, 2), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(6, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(7, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(7, 10), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 11), GridTypes.BeamColor.BLUE),
		TilePlacement.make_emitter(Vector2i(0, 11), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_switch(Vector2i(1, 11), "g3"),
		TilePlacement.make_mirror(Vector2i(2, 11), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_blocker(Vector2i(2, 10)),
	]
