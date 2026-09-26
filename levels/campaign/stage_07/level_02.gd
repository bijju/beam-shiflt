extends LevelData
## Campaign Level 62 — "Longcut". Post-60 Levels 61-70.
## The reflected branch's real solution deliberately loops far out of
## the way (up and around through a 2-mirror detour) before reaching
## the mirror that actually decides the route - one orientation there
## is a dead end, the other continues the intentionally long correct
## path. See CAMPAIGN_DESIGN.md section 11j.

func _init() -> void:
	level_id = 2
	display_name = "Longcut"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: the reflected branch's correct route is deliberately the LONGER of two plausible continuations at mirror (4,2) - the direct-looking LEFT exit is a dead end, while the correct RIGHT continuation adds two more mirrors before the target. Straight branch (unconditional RIGHT off splitter (2,4)): mirror (3,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (2,8)'s sibling... no, into a dead run - mirror (3,6) flips to BACKSLASH (RIGHT), into target A (5,6, WHITE). Reflected branch: splitter flips to SLASH (UP), mirror (2,2) flips to BACKSLASH (LEFT), mirror (1,2) flips to BACKSLASH (UP), mirror (1,0) flips to SLASH (RIGHT), mirror (4,0) flips to BACKSLASH (DOWN), mirror (4,2) flips to BACKSLASH (RIGHT, NOT the tempting LEFT dead-end), mirror (5,2) flips to BACKSLASH (DOWN), mirror (5,4) flips to BACKSLASH (RIGHT), into target B (6,4, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,8) instead. INTENTIONAL DECOY: mirror (7,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 9
	optimal_moves = 10
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 8)),
		TilePlacement.make_mirror(Vector2i(7, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 6), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 4), GridTypes.BeamColor.WHITE),
	]
