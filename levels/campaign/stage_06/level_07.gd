extends LevelData
## Campaign Level 57 — "Long Division". Post-reboot Levels 51-60.
## A single beam threads a 9-mirror chain through two filters and two
## fixed mirrors - the target's color can only be reasoned out by
## working backward through the second fixed mirror's orientation to
## see which filter actually survives. See CAMPAIGN_DESIGN.md section
## 11i.

func _init() -> void:
	level_id = 7
	display_name = "Long Division"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: one continuous beam, no splitter - RED then GREEN filters in sequence (last wins), routed through a fixed mirror mid-chain and a second fixed mirror right before the target, so the player has to reason backward from the target's GREEN requirement through both fixed mirrors to confirm the beam's actual final color before ever touching a rotatable piece. Chain: emitter (0,2) RIGHT WHITE -> mirror (2,2) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (2,0) instead - mirror (2,3) flips to BACKSLASH (RIGHT) -> mirror (3,3) flips to BACKSLASH (DOWN) -> mirror (3,5) flips to BACKSLASH (RIGHT) -> filter (4,5) RED -> mirror (5,5) flips to BACKSLASH (DOWN) -> fixed mirror (5,7, BACKSLASH, DOWN->RIGHT) -> filter (6,7) GREEN (overwrites RED) -> mirror (7,7) flips to BACKSLASH (DOWN) -> mirror (7,8) flips to BACKSLASH (RIGHT) -> mirror (8,8) flips to SLASH (UP) -> mirror (8,7) flips to SLASH (RIGHT) -> fixed mirror (9,7, BACKSLASH, RIGHT->DOWN) -> target A (9,10, GREEN). INTENTIONAL DECOY: mirror (1,8) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 11
	optimal_moves = 9
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(2, 0)),
		TilePlacement.make_mirror(Vector2i(1, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 5), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 7), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_filter(Vector2i(6, 7), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(7, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(7, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(8, 8), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(8, 7), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(9, 7), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(9, 10), GridTypes.BeamColor.GREEN),
	]
