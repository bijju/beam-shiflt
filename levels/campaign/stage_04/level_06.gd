extends LevelData
## Campaign Level 36 — "Vertex". DIFFICULTY REWORK PASS 2.
## Two independent emitters (no splitter) converge on ONE fixed shared
## mirror from perpendicular directions - the player has to plan both
## chains before touching anything, since the shared mirror's single
## orientation has to work for both simultaneously.
## See CAMPAIGN_DESIGN.md section 11g (Pass 2).

func _init() -> void:
	level_id = 6
	display_name = "Vertex"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: emitters 1 and 2 are entirely independent beams that happen to converge on fixed mirror (3,6) from perpendicular directions - emitter 1 arrives RIGHT (BACKSLASH: RIGHT->DOWN, to target A below), emitter 2 arrives LEFT (BACKSLASH: LEFT->UP, to a relay mirror above). Emitter 1 chain: mirror (1,3) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,1) instead - mirror (1,4) flips to BACKSLASH (RIGHT), mirror (2,4) flips to BACKSLASH (DOWN), mirror (2,6) flips to BACKSLASH (RIGHT), into the shared mirror. Emitter 2 chain: mirror (5,0) flips to BACKSLASH (DOWN), mirror (5,3) flips to BACKSLASH (RIGHT), mirror (6,3) flips to BACKSLASH (DOWN), mirror (6,6) flips to SLASH (LEFT), into the shared mirror from the east -> UP -> mirror (3,1) flips to SLASH (RIGHT) -> target B (4,1, WHITE). (A first draft placed target B directly at (4,0), on emitter 2's own unavoidable first straight shot along row 0 - the solver caught a 4-move shortcut where the beam simply passed through it before ever reaching a single mirror. Fixed by routing the shared mirror's output through a dedicated relay mirror at (3,1) that turns it away from row 0 entirely before it reaches a target.) INTENTIONAL DECOY: mirror (6,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 9
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 1)),
		TilePlacement.make_mirror(Vector2i(1, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(3, 7), GridTypes.BeamColor.WHITE),
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(5, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 1), GridTypes.BeamColor.WHITE),
	]
