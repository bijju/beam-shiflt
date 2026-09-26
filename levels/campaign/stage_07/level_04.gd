extends LevelData
## Campaign Level 64 — "Twin Anchor". Post-60 Levels 61-70.
## Two independent emitters converge on ONE fixed shared mirror from
## perpendicular directions - the player must reason backward for BOTH
## emitters at once, since neither approach direction can be adjusted
## after the fact. See CAMPAIGN_DESIGN.md section 11j.

func _init() -> void:
	level_id = 4
	display_name = "Twin Anchor"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: fixed mirror (4,4) is hit by both emitters from perpendicular directions - emitter 1 arrives DOWN (BACKSLASH: DOWN->RIGHT, to target A east of the mirror), emitter 2 arrives UP (BACKSLASH: UP->LEFT, to target B west of it) - both approach chains have to be engineered around the SAME fixed orientation, so backward reasoning has to be done for both emitters simultaneously before either rotatable mirror is touched. Emitter 1 chain: mirror (2,1) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (2,0) instead - mirror (2,2) flips to BACKSLASH (RIGHT), mirror (3,2) flips to BACKSLASH (DOWN), mirror (3,3) flips to BACKSLASH (RIGHT), mirror (4,3) flips to BACKSLASH (DOWN), into the shared mirror -> RIGHT -> target A (5,4, WHITE). Emitter 2 chain: mirror (2,7) flips to SLASH (UP), mirror (2,6) flips to BACKSLASH (LEFT), mirror (1,6) flips to BACKSLASH (UP), mirror (1,5) flips to SLASH (RIGHT), mirror (4,5) flips to SLASH (UP), into the shared mirror from the south -> LEFT -> target B (2,4, WHITE). INTENTIONAL DECOY: mirror (6,7) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 10
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(2, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(2, 0)),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(5, 4), GridTypes.BeamColor.WHITE),
		TilePlacement.make_target(Vector2i(2, 4), GridTypes.BeamColor.WHITE),
		TilePlacement.make_emitter(Vector2i(0, 7), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(2, 7), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(6, 7), GridTypes.MirrorOrientation.SLASH),
	]
