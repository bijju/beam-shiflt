extends LevelData
## Campaign Level 28 — "Gambit". DIFFICULTY REWORK PASS 2.
## Splitter with two independently-colored branches (RED / BLUE), each
## needing its own filter and its own multi-mirror chain, plus an
## emergent cascade: a wrong second-branch mirror doesn't just miss its
## target, it runs the beam straight back into the same hazard.
## See CAMPAIGN_DESIGN.md section 11f (Pass 2).

func _init() -> void:
	level_id = 8
	display_name = "Gambit"
	stage = "Split"
	developer_notes = "DESIGN INTENT: two color-independent target assignments off one splitter, each requiring its own filter. Straight branch (unconditional RIGHT off splitter (1,2)): filter (2,2) sets RED, mirror (3,2) flips to BACKSLASH (DOWN), mirror (3,6) flips to BACKSLASH (RIGHT), into target A (5,6, RED). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), filter (2,0) sets BLUE, mirror (4,0) flips to BACKSLASH (DOWN), mirror (4,4) flips to BACKSLASH (RIGHT), into target B (5,4, BLUE). EMERGENT CASCADE (not scripted, solver-confirmed): if mirror (3,6) is left at its authored SLASH, the straight branch's beam is deflected LEFT and runs directly into the hazard at (1,6) - the same hazard that punishes the wrong splitter orientation, discovered as a bonus consequence during authoring, not designed in from the start. INTENTIONAL DECOY: mirror (5,2) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 6)),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(2, 2), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 6), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(2, 0), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 4), GridTypes.BeamColor.BLUE),
	]
