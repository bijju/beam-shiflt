extends LevelData
## Campaign Level 40 — "Crucible". DIFFICULTY REWORK PASS 2, block finale.
## The hardest puzzle in the block: a portal-routed straight branch and a
## 2-filter-order reflected branch converge on one fixed shared mirror,
## with a blocker guarding the straight branch's false fork.
## See CAMPAIGN_DESIGN.md section 11g (Pass 2).

func _init() -> void:
	level_id = 10
	display_name = "Crucible"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: filter order + portal routing + a fixed cross-branch mirror, all in one puzzle. Straight branch (unconditional RIGHT off splitter (1,3)): mirror (2,3) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (2,1) instead - mirror (2,5) flips to BACKSLASH (RIGHT), mirror (3,5) flips to BACKSLASH (DOWN), mirror (3,6) flips to BACKSLASH (RIGHT), into portal (4,6)/pair A -> exits (5,7) still moving RIGHT -> into the shared mirror -> DOWN -> target A (6,8, WHITE). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), filter (2,0) sets RED, filter (3,0) sets GREEN (last one wins), mirror (4,0) flips to BACKSLASH (DOWN), mirror (4,2) flips to BACKSLASH (RIGHT), mirror (5,2) flips to BACKSLASH (DOWN), mirror (5,3) flips to BACKSLASH (RIGHT), mirror (6,3) flips to BACKSLASH (DOWN), into the shared mirror from the north -> RIGHT -> target B (7,7, GREEN). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,6) instead. INTENTIONAL DECOY: mirror (7,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 9
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 6)),
		TilePlacement.make_blocker(Vector2i(2, 1)),
		TilePlacement.make_mirror(Vector2i(7, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(4, 6), "A"),
		TilePlacement.make_portal(Vector2i(5, 7), "A"),
		TilePlacement.make_mirror(Vector2i(6, 7), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(6, 8), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(2, 0), GridTypes.BeamColor.RED),
		TilePlacement.make_filter(Vector2i(3, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 7), GridTypes.BeamColor.GREEN),
	]
