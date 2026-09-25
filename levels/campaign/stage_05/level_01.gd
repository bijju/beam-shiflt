extends LevelData
## Campaign Level 41 — "Foresight". DIFFICULTY REWORK PASS 2.
## Splitter feeding two independent color-coded backward-reasoning
## chains, each ending at its own fixed mirror.
## See CAMPAIGN_DESIGN.md section 11h (Pass 2).

func _init() -> void:
	level_id = 1
	display_name = "Foresight"
	stage = "Filters"
	developer_notes = "DESIGN INTENT: two disjoint filter+fixed-mirror backward-reasoning chains off one splitter - the player has to work out both target colors and both approach directions before making a move. Straight branch (unconditional RIGHT off splitter (1,4)): mirror (2,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (2,2) instead - mirror (2,5) flips to BACKSLASH (RIGHT), mirror (3,5) flips to BACKSLASH (DOWN), mirror (3,6) flips to BACKSLASH (RIGHT), filter (4,6) sets RED, into fixed mirror (5,6, BACKSLASH, RIGHT->DOWN) -> target A (5,7, RED). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), mirror (2,0) flips to BACKSLASH (DOWN), mirror (2,1) flips to BACKSLASH (RIGHT), filter (3,1) sets BLUE, into fixed mirror (4,1, BACKSLASH, RIGHT->DOWN) -> target B (4,3, BLUE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,6) instead. No decoys - every rotatable piece is load-bearing (solver-confirmed)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 8
	optimal_moves = 8
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 6)),
		TilePlacement.make_blocker(Vector2i(2, 2)),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 6), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(5, 7), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(3, 1), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(4, 3), GridTypes.BeamColor.BLUE),
	]
