extends LevelData
## Campaign Level 52 — "Currents". Post-reboot Levels 51-60.
## A single beam is recolored TWICE across a portal jump - the first
## filter's color is a red herring; only the color set AFTER the portal
## (by the second filter) determines the target requirement. See
## CAMPAIGN_DESIGN.md section 11i.

func _init() -> void:
	level_id = 2
	display_name = "Currents"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: the beam is RED after the first filter, crosses a portal, and is recolored BLUE by a second filter afterward - last filter touched wins, so the first recolor never mattered, but the player has to trace all the way through the portal to see it. Chain: emitter (0,3) RIGHT WHITE -> mirror (1,3) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,1) instead - mirror (1,4) flips to BACKSLASH (RIGHT) -> mirror (2,4) flips to BACKSLASH (DOWN) -> filter (2,5) RED -> mirror (2,6) flips to BACKSLASH (RIGHT) -> portal (3,6)/pair A -> exits (4,2) still moving RIGHT -> mirror (5,2) flips to BACKSLASH (DOWN) -> filter (5,3) BLUE (overwrites RED) -> mirror (5,4) flips to SLASH (LEFT) -> mirror (4,4) flips to BACKSLASH (UP) -> mirror (4,3) flips to BACKSLASH (LEFT) -> fixed mirror (3,3, BACKSLASH, LEFT->UP) -> target A (3,0, BLUE). INTENTIONAL DECOY: mirror (5,6) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 8
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 1)),
		TilePlacement.make_mirror(Vector2i(1, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(2, 5), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(3, 6), "A"),
		TilePlacement.make_portal(Vector2i(4, 2), "A"),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 3), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 3), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(3, 0), GridTypes.BeamColor.BLUE),
	]
