extends LevelData
## Campaign Level 63 — "Invalidation". Post-60 Levels 61-70.
## The straight branch's wrong turn reaches a plausible-looking decoy
## target of the wrong color; the real route needs a genuinely closed
## gate that only the reflected branch's switch opens. See
## CAMPAIGN_DESIGN.md section 11j.
##
## (A first draft used an always-open "decoy" gate positioned where the
## reflected branch's OWN correct path also passed through it, and a
## "decoy" mirror that turned out to connect reflected's chain straight
## into straight's own target - the solver found a 5-move shortcut.
## Rebuilt with fully disjoint branch zones and no always-open gate.)

func _init() -> void:
	level_id = 3
	display_name = "Invalidation"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: mirror (3,5), if left at its authored SLASH, sends the beam UP to a non-required RED decoy target at (3,2) - it looks like a solve but is the wrong color, and the real route needs a genuinely CLOSED gate that only the reflected branch's switch opens. Straight branch (unconditional RIGHT off splitter (2,5)): mirror (3,5) flips to BACKSLASH (DOWN), through gate (3,6) [g1, opened by the reflected branch], mirror (3,7) flips to BACKSLASH (RIGHT), mirror (4,7) flips to BACKSLASH (DOWN), mirror (4,8) flips to BACKSLASH (RIGHT), into portal (5,8)/pair A -> exits (6,2) still moving RIGHT -> target A (7,2, WHITE). Reflected branch: splitter flips to SLASH (UP), mirror (2,2) flips to BACKSLASH (LEFT), mirror (1,2) flips to BACKSLASH (UP), mirror (1,0) flips to SLASH (RIGHT), mirror (4,0) flips to BACKSLASH (DOWN), switch (4,1) [g1], mirror (4,3) flips to BACKSLASH (RIGHT), into target B (5,3, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,7) instead. INTENTIONAL DECOY: mirror (7,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 9
	optimal_moves = 10
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(2, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 7)),
		TilePlacement.make_mirror(Vector2i(7, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(3, 2), GridTypes.BeamColor.RED, false),
		TilePlacement.make_gate(Vector2i(3, 6), "g1", false),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(5, 8), "A"),
		TilePlacement.make_portal(Vector2i(6, 2), "A"),
		TilePlacement.make_target(Vector2i(7, 2), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(4, 1), "g1"),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 3), GridTypes.BeamColor.WHITE),
	]
