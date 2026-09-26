extends LevelData
## Campaign Level 42 — "Hindsight". DIFFICULTY REWORK PASS 2.
## One deep single-beam chain, no splitter - portal, filter, and a fixed
## mirror in the middle of the chain, deliberately a different shape
## from its splitter-heavy neighbors.
## See CAMPAIGN_DESIGN.md section 11h (Pass 2).

func _init() -> void:
	level_id = 2
	display_name = "Hindsight"
	stage = "Filters"
	developer_notes = "DESIGN INTENT: one continuous beam, nine mirrors, no splitter - deliberately linear so the player has to hold the whole route in their head at once rather than reasoning about independent branches. Chain: emitter (0,5) RIGHT WHITE -> mirror (1,5) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,2) instead - mirror (1,7) flips to BACKSLASH (RIGHT) -> portal (2,7)/pair A -> exits (5,2) still moving RIGHT -> mirror (6,2) flips to BACKSLASH (DOWN) -> filter (6,4) RED -> mirror (6,5) flips to SLASH (LEFT) -> mirror (5,5) flips to BACKSLASH (UP) -> mirror (5,4) flips to BACKSLASH (LEFT) -> mirror (4,4) flips to BACKSLASH (UP) -> fixed mirror (4,2, BACKSLASH, UP->LEFT) -> mirror (3,2) flips to BACKSLASH (UP) -> mirror (3,0) flips to BACKSLASH (LEFT) -> target A (2,0, RED). INTENTIONAL DECOY: mirror (0,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 9
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 2)),
		TilePlacement.make_mirror(Vector2i(0, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(2, 7), "A"),
		TilePlacement.make_portal(Vector2i(5, 2), "A"),
		TilePlacement.make_mirror(Vector2i(6, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(6, 4), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(6, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(2, 0), GridTypes.BeamColor.RED),
	]
