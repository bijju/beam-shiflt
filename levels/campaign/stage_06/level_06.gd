extends LevelData
## Campaign Level 56 — "Shared Transit". Post-reboot Levels 51-60.
## Two independent emitters each thread their own separate portal, but
## emitter 2's gate only opens once emitter 1's beam trips a switch
## AFTER its own portal exit - a genuine multi-emitter dependency built
## from proven-safe pieces rather than sharing one portal pair (see the
## rejected first draft below). See CAMPAIGN_DESIGN.md section 11i.

func _init() -> void:
	level_id = 6
	display_name = "Shared Transit"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: emitter 2 is physically gated until emitter 1's beam crosses a portal AND a switch beyond it - the switch is deliberately placed AFTER the portal exit, so the player has to trace emitter 1's route all the way through before realizing what it unlocks. Emitter 1 chain: mirror (2,3) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (2,2) instead - into portal (2,4)/pair A -> exits (5,7) still moving DOWN -> mirror (5,8) flips to BACKSLASH (RIGHT) -> switch (6,8) [g1] -> mirror (7,8) flips to BACKSLASH (DOWN) -> mirror (7,9) flips to SLASH (LEFT) -> target A (3,9, WHITE). Emitter 2 chain: mirror (1,0) flips to BACKSLASH (DOWN), mirror (1,1) flips to BACKSLASH (RIGHT), through gate (2,1) [g1, opened by emitter 1's switch], mirror (4,1) flips to BACKSLASH (DOWN), into portal (4,2)/pair B -> exits (7,6) still moving DOWN -> mirror (7,7) flips to BACKSLASH (RIGHT), into target B (8,7, WHITE). (A first draft had both emitters share ONE portal pair, each entering the opposite end - this created a combinatorially pathological search space during solver validation, taking minutes per run instead of milliseconds, a strong signal the interaction was also too confusing for a player to reason about. Rebuilt with two separate portal pairs tied together by a switch/gate instead - fast to validate and clear to trace.) INTENTIONAL DECOY: mirror (8,9) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 8
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(2, 2)),
		TilePlacement.make_portal(Vector2i(2, 4), "A"),
		TilePlacement.make_portal(Vector2i(5, 7), "A"),
		TilePlacement.make_mirror(Vector2i(5, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 8), "g1"),
		TilePlacement.make_mirror(Vector2i(7, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(7, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(3, 9), GridTypes.BeamColor.WHITE),
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(2, 1), "g1", false),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(4, 2), "B"),
		TilePlacement.make_portal(Vector2i(7, 6), "B"),
		TilePlacement.make_mirror(Vector2i(7, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 7), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(8, 9), GridTypes.MirrorOrientation.SLASH),
	]
