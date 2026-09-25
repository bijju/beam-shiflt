extends LevelData
## Campaign Level 66 — "Portal Trap". Post-60 Levels 61-70.
## One deep linear chain (no splitter) - the mirror right after the
## portal exit offers two plausible continuations, and the
## geometrically "closer-looking" one runs straight into a hazard.
## See CAMPAIGN_DESIGN.md section 11j.

func _init() -> void:
	level_id = 6
	display_name = "Portal Trap"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: mirror (5,6), reached right after the portal exit, has two plausible continuations - UP looks like the shorter, more direct route toward the target's general area, but runs straight into the hazard at (5,4); the correct DOWN continuation is the longer way around. Chain: emitter (0,1) RIGHT WHITE -> mirror (1,1) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,0) instead - mirror (1,2) flips to BACKSLASH (RIGHT) -> mirror (2,2) flips to BACKSLASH (DOWN) -> mirror (2,4) flips to BACKSLASH (RIGHT) -> portal (3,4)/pair A -> exits (4,6) still moving RIGHT -> mirror (5,6) flips to BACKSLASH (DOWN, NOT the tempting UP that hits the hazard at (5,4)) -> mirror (5,7) flips to BACKSLASH (RIGHT) -> mirror (6,7) flips to SLASH (UP) -> target A (6,5, WHITE). Kept to 7 real moves rather than padded further - the reasoning load is entirely in correctly identifying which of the two portal-exit continuations is the trap, not in route length."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 0)),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(3, 4), "A"),
		TilePlacement.make_portal(Vector2i(4, 6), "A"),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(5, 4)),
		TilePlacement.make_mirror(Vector2i(5, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 7), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(6, 5), GridTypes.BeamColor.WHITE),
	]
