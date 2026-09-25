extends LevelData
## Campaign Level 61 — "Peripheral". Post-60 Levels 61-70 (internal
## folder stage_07), continuing directly from Level 60's difficulty -
## no mechanic-teaching reset. See CAMPAIGN_DESIGN.md section 11j.
##
## The straight branch (visually closest to the emitter) is short and
## simple; the real puzzle is the reflected branch, which the player
## has to notice requires planning FIRST even though it's the branch
## further from the emitter.

func _init() -> void:
	level_id = 1
	display_name = "Peripheral"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: the visually closer, simpler-looking straight branch is a 2-move afterthought; the real puzzle - and the branch that should be planned FIRST - is the longer reflected branch. Straight branch (unconditional RIGHT off splitter (1,5)): mirror (2,5) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (2,3) instead - mirror (2,6) flips to BACKSLASH (RIGHT), into target A (4,6, WHITE). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), filter (2,0) RED, mirror (3,0) flips to BACKSLASH (DOWN), mirror (3,1) flips to BACKSLASH (RIGHT), mirror (4,1) flips to BACKSLASH (DOWN), filter (4,2) GREEN (overwrites RED), mirror (4,3) flips to BACKSLASH (RIGHT), mirror (5,3) flips to BACKSLASH (DOWN), mirror (5,4) flips to SLASH (LEFT), into target B (3,4, GREEN). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,7) instead. INTENTIONAL DECOY: mirror (6,7) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 10
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 7)),
		TilePlacement.make_blocker(Vector2i(2, 3)),
		TilePlacement.make_mirror(Vector2i(6, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 6), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(2, 0), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 2), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(3, 4), GridTypes.BeamColor.GREEN),
	]
