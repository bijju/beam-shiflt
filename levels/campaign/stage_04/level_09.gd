extends LevelData
## Campaign Level 39 — "Riddle". DIFFICULTY REWORK PASS 2.
## Splitter feeding two fully independent backward-reasoning puzzles -
## each branch ends at its own fixed mirror whose orientation determines
## the required upstream approach direction.
## See CAMPAIGN_DESIGN.md section 11g (Pass 2).

func _init() -> void:
	level_id = 9
	display_name = "Riddle"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: two disjoint fixed-mirror backward-reasoning puzzles off one splitter - the player has to solve both independently before making any move. Straight branch (unconditional RIGHT off splitter (1,3)): mirror (2,3) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (2,2) instead - mirror (2,4) flips to BACKSLASH (RIGHT), mirror (3,4) flips to BACKSLASH (DOWN), mirror (3,5) flips to BACKSLASH (RIGHT), into fixed mirror (4,5, BACKSLASH, RIGHT->DOWN) -> target A (4,6, WHITE). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), mirror (3,0) flips to BACKSLASH (DOWN), mirror (3,1) flips to BACKSLASH (RIGHT), mirror (4,1) flips to BACKSLASH (DOWN), into fixed mirror (4,2, BACKSLASH, DOWN->RIGHT) -> target B (5,2, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,5) instead. INTENTIONAL DECOY: mirror (5,4) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 9
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 5)),
		TilePlacement.make_blocker(Vector2i(2, 2)),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 5), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(4, 6), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(5, 2), GridTypes.BeamColor.WHITE),
	]
