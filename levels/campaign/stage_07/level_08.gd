extends LevelData
## Campaign Level 68 — "Twin Corridor". Post-60 Levels 61-70, MASTER
## TIER. Two emitters cross the SAME physical gate cell from
## perpendicular directions (one horizontal, one vertical) - EITHER
## emitter's own switch opens it for BOTH. See CAMPAIGN_DESIGN.md
## section 11j.

func _init() -> void:
	level_id = 8
	display_name = "Twin Corridor"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: gate (4,5) is a single shared corridor both emitters must cross - emitter 1 horizontally (RIGHT), emitter 2 vertically (DOWN) - and EITHER emitter's own switch (both wired to the same gate_id) opens it for both, so the player can solve either chain first and the gate resolves via simulate_until_stable's multi-pass evaluation regardless of order. Emitter 1 chain: mirror (1,5) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,3) instead - mirror (1,7) flips to BACKSLASH (RIGHT), switch (2,7) [g1], mirror (3,7) is ALREADY correctly authored at SLASH (RIGHT->UP, no flip needed - a genuine zero-move load-bearing piece, not a decoy: toggling it breaks the solution even though the solved state never touches it), mirror (3,5) flips to SLASH (RIGHT->UP wait UP->RIGHT), through the shared gate -> mirror (5,5) flips to BACKSLASH (DOWN) -> target A (5,7, WHITE). Emitter 2 (fires DOWN from (4,0)) chain: switch (4,1) [g1], mirror (4,2) flips to BACKSLASH (RIGHT), mirror (5,2) flips to BACKSLASH (DOWN), mirror (5,3) flips to SLASH (LEFT), mirror (4,3) flips to SLASH (DOWN), through the SAME shared gate from the north -> mirror (4,6) flips to BACKSLASH (RIGHT) -> target B (6,6, WHITE). Solver-confirmed optimal is 9, not 10 - an earlier hand-trace mis-applied the reflect table to mirror (3,7) and assumed it needed a flip that the solver correctly showed was unnecessary. INTENTIONAL DECOY: mirror (7,8) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 9
	optimal_moves = 9
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 3)),
		TilePlacement.make_mirror(Vector2i(1, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(2, 7), "g1"),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(4, 5), "g1", false),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 7), GridTypes.BeamColor.WHITE),
		TilePlacement.make_emitter(Vector2i(4, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_switch(Vector2i(4, 1), "g1"),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 6), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(7, 8), GridTypes.MirrorOrientation.SLASH),
	]
