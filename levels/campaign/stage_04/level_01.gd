extends LevelData
## Campaign Level 31 — "Ambush". DIFFICULTY REWORK PASS 2.
## A single beam threads a portal partway through a long six-mirror
## chain; a wrong very first turn runs straight into a hazard instead of
## a harmless miss.
## See CAMPAIGN_DESIGN.md section 11g (Pass 2).

func _init() -> void:
	level_id = 1
	display_name = "Ambush"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: a single continuous beam threads a portal partway through a 6-mirror chain, with the portal preserving direction and color across the jump. Chain: emitter (0,2) RIGHT WHITE -> mirror (1,2) flips to BACKSLASH (DOWN) -> portal (1,4)/pair A -> exits (4,0) still moving DOWN -> mirror (4,1) flips to BACKSLASH (RIGHT) -> mirror (5,1) flips to BACKSLASH (DOWN) -> mirror (5,4) flips to SLASH (LEFT) -> mirror (2,4) flips to SLASH (DOWN) -> mirror (2,5) flips to BACKSLASH (RIGHT) -> target A (4,5, WHITE). If mirror (1,2) is left at its authored SLASH, the very first turn sends the beam UP into the hazard at (1,0) instead of into the portal - the whole rest of the chain never even gets a chance to matter. (A first draft tried to have the beam loop back through an earlier mirror on its way to the target - the solver found an unintended second path through that same mirror cluster that reached the target without ever using the portal at all. Rebuilt as a single non-revisiting chain, which cannot self-collide.) INTENTIONAL DECOY: mirror (5,6) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 0)),
		TilePlacement.make_portal(Vector2i(1, 4), "A"),
		TilePlacement.make_portal(Vector2i(4, 0), "A"),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 5), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.SLASH),
	]
