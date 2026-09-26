extends LevelData
## Campaign Level 81 — "Third Signal". EXTREME ENTRY TIER (Levels 81-90).
## Built by extending Level 74's already-validated two-emitter/target-
## continuation/portal geometry: emitter 1's tail is rerouted through
## two more forced bends before its target, and emitter 2's own tail now
## also depends on a THIRD, completely separate emitter's short chain -
## a genuine 3-way convergence (emitter 1 gates emitter 2's start,
## emitter 3 gates emitter 2's tail) rather than a single pairwise
## dependency. See CAMPAIGN_DESIGN.md section 11l.

func _init() -> void:
	level_id = 1
	display_name = "Third Signal"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: emitter 2's route to target B now needs BOTH gate (8,2) [g1, opened by emitter 1's post-target continuation, exactly as in Level 74] AND a new gate (7,3) [g3, opened by a completely separate third emitter's own short 2-mirror chain] - two independent upstream sources converging on one downstream path. Emitter 1 chain (first 4 mirrors identical to Level 74): mirror (1,3) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,1) instead - mirror (1,4) flips to BACKSLASH (RIGHT), mirror (2,4) flips to BACKSLASH (DOWN), mirror (2,5) flips to BACKSLASH (RIGHT), into portal (3,5)/pair A -> exits (4,6) still moving RIGHT -> mirror (5,6) flips to BACKSLASH (DOWN) -> filter (5,7) GREEN -> mirror (5,8) flips to BACKSLASH (RIGHT) -> target A (6,8, GREEN), continues RIGHT past it into switch (7,8) [g1]. Emitter 2 (fires DOWN from (7,0)) chain: mirror (7,1) flips to BACKSLASH (RIGHT), mirror (8,1) flips to BACKSLASH (DOWN), through gate (8,2) [g1], mirror (8,3) flips to SLASH (LEFT), through gate (7,3) [g3, opened by emitter 3], filter (5,3) RED, mirror (4,3) flips to BACKSLASH (UP), into target B (4,0, RED). Emitter 3 (fires RIGHT from (0,9), a completely separate short chain with no other relationship to the rest of the board): mirror (1,9) flips to SLASH (UP) - if left at its authored BACKSLASH the beam runs DOWN and exits the grid immediately, and g3 never opens - mirror (1,8) flips to SLASH (RIGHT) -> switch (2,8) [g3] -> blocker (3,8) stops the beam there, harmlessly. INTENTIONAL DECOY: mirror (8,9) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 12
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 1)),
		TilePlacement.make_mirror(Vector2i(1, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(3, 5), "A"),
		TilePlacement.make_portal(Vector2i(4, 6), "A"),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 7), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(5, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 8), GridTypes.BeamColor.GREEN),
		TilePlacement.make_switch(Vector2i(7, 8), "g1"),
		TilePlacement.make_emitter(Vector2i(7, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(7, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(8, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(8, 2), "g1", false),
		TilePlacement.make_mirror(Vector2i(8, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(7, 3), "g3", false),
		TilePlacement.make_filter(Vector2i(5, 3), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 0), GridTypes.BeamColor.RED),
		TilePlacement.make_emitter(Vector2i(0, 9), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(1, 8), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(2, 8), "g3"),
		TilePlacement.make_blocker(Vector2i(3, 8)),
		TilePlacement.make_mirror(Vector2i(8, 9), GridTypes.MirrorOrientation.SLASH),
	]
