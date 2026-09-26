extends LevelData
## Campaign Level 45 — "Threshold". DIFFICULTY REWORK PASS 2, pre-46-50
## bridge finale. Combines portal routing on the straight branch with a
## 2-filter order chain on the reflected branch, both converging on one
## fixed shared mirror - the block's hardest puzzle, transitioning into
## the unchanged Levels 46-50.
## See CAMPAIGN_DESIGN.md section 11h (Pass 2).

func _init() -> void:
	level_id = 5
	display_name = "Threshold"
	stage = "Filters"
	developer_notes = "DESIGN INTENT: a portal-routed branch and a 2-filter-order branch converge on one fixed shared mirror, bridging into the unchanged 46-50 block. Straight branch (unconditional RIGHT off splitter (1,4)): mirror (2,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (2,1) instead - mirror (2,5) flips to BACKSLASH (RIGHT), filter (3,5) sets RED, mirror (4,5) flips to BACKSLASH (DOWN), mirror (4,6) flips to BACKSLASH (RIGHT), into portal (5,6)/pair A -> exits (6,8) still moving RIGHT -> into the shared mirror -> DOWN -> target A (7,9, RED). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), filter (2,0) sets GREEN, filter (3,0) sets BLUE (last one wins), mirror (4,0) flips to BACKSLASH (DOWN), mirror (4,3) flips to BACKSLASH (RIGHT), mirror (5,3) flips to BACKSLASH (DOWN), mirror (5,4) flips to BACKSLASH (RIGHT), mirror (7,4) flips to BACKSLASH (DOWN), into the shared mirror from the north -> RIGHT -> target B (8,8, BLUE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,6) instead. INTENTIONAL DECOY: mirror (0,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 6)),
		TilePlacement.make_blocker(Vector2i(2, 1)),
		TilePlacement.make_mirror(Vector2i(0, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(3, 5), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(4, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(5, 6), "A"),
		TilePlacement.make_portal(Vector2i(6, 8), "A"),
		TilePlacement.make_mirror(Vector2i(7, 8), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(7, 9), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(2, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_filter(Vector2i(3, 0), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(7, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 8), GridTypes.BeamColor.BLUE),
	]
