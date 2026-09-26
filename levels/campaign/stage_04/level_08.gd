extends LevelData
## Campaign Level 38 — "Quandary". DIFFICULTY REWORK PASS 2.
## Splitter where the straight branch chains two filters (RED then BLUE,
## last one wins) and the reflected branch's wrong orientation runs into
## a hazard instead of a harmless miss.
## See CAMPAIGN_DESIGN.md section 11g (Pass 2).

func _init() -> void:
	level_id = 8
	display_name = "Quandary"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: the straight branch's target requires the SECOND filter's color (BLUE), not the first (RED) it passes through - last filter wins. Straight branch (unconditional RIGHT off splitter (1,3)): filter (2,3) sets RED, mirror (3,3) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,2) instead - filter (3,4) sets BLUE, mirror (3,6) flips to BACKSLASH (RIGHT), into target A (5,6, BLUE). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), mirror (4,0) flips to BACKSLASH (DOWN), mirror (4,4) flips to BACKSLASH (RIGHT), into target B (5,4, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,6) instead. INTENTIONAL DECOY: mirror (5,3) sits between the two targets, plausible as a shared relay, but no beam in any configuration ever reaches it (solver-confirmed)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 6)),
		TilePlacement.make_blocker(Vector2i(3, 2)),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(2, 3), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(3, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(3, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 6), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 4), GridTypes.BeamColor.WHITE),
	]
