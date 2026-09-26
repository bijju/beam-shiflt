extends LevelData
## Campaign Level 88 — "Distant Triple Relay". NEAR-MASTER-FINAL TIER
## (Levels 81-90). Built by extending Level 87's already-validated
## three-stage relay geometry: both emitter 1's and emitter 2's final
## deliveries now jump through their own separate portals into distant,
## previously-unused corners of the board before reaching their
## targets - non-local portal reasoning layered directly onto the first
## three-way relay, on TWO of its three branches at once.
## See CAMPAIGN_DESIGN.md section 11l.

func _init() -> void:
	level_id = 8
	display_name = "Distant Triple Relay"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical three-stage relay core to Level 87 (emitter 1's unconditional switch opens emitter 2's early gate; emitter 2's switch opens emitter 3's early gate; emitter 3's switch opens the final gate on emitter 1's own tail) - but now BOTH emitter 1's and emitter 2's deliveries, after clearing their own portion of the relay, jump through their own separate portal pairs into distant corners of the board before reaching their relocated targets. Emitter 1 chain (identical to Level 87 up to mirror (6,9)): mirror (2,2) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (2,0) instead - switch (2,4) [gA], through gate (2,5) [gC], mirror (2,6) flips to BACKSLASH (RIGHT), mirror (3,6) flips to BACKSLASH (DOWN), mirror (3,7) flips to BACKSLASH (RIGHT), filter (5,7) BLUE, mirror (6,7) flips to BACKSLASH (DOWN), mirror (6,9) flips to BACKSLASH (RIGHT), into portal (7,9)/pair P -> exits (0,1) still moving RIGHT -> mirror (3,1) flips to BACKSLASH (DOWN) -> target A (3,4, BLUE). Emitter 2 chain (identical to Level 87 up to switch (6,10)): mirror (4,9) flips to BACKSLASH (DOWN), through gate (4,10) [gA], mirror (4,11) flips to BACKSLASH (RIGHT), mirror (5,11) flips to SLASH (UP), mirror (5,10) flips to SLASH (RIGHT), switch (6,10) [gB], into portal (7,10)/pair Q -> exits (0,11) still moving RIGHT -> mirror (1,11) flips to SLASH (UP) - if left at its authored BACKSLASH the beam runs DOWN and exits the grid immediately instead - filter (1,10) GREEN -> target B (1,9, GREEN). Emitter 3 (fires DOWN from (8,0), identical to Level 87, needs no mirror at all): through gate (8,1) [gB] -> switch (8,2) [gC] -> blocker (8,4) stops the beam there, harmlessly. INTENTIONAL DECOY: mirror (9,11) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 12
	optimal_moves = 12
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(2, 0)),
		TilePlacement.make_switch(Vector2i(2, 4), "gA"),
		TilePlacement.make_gate(Vector2i(2, 5), "gC", false),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(6, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(7, 9), "P"),
		TilePlacement.make_portal(Vector2i(0, 1), "P"),
		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(3, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_emitter(Vector2i(0, 9), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(4, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(4, 10), "gA", false),
		TilePlacement.make_mirror(Vector2i(4, 11), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 11), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(5, 10), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(6, 10), "gB"),
		TilePlacement.make_portal(Vector2i(7, 10), "Q"),
		TilePlacement.make_portal(Vector2i(0, 11), "Q"),
		TilePlacement.make_mirror(Vector2i(1, 11), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(1, 10), GridTypes.BeamColor.GREEN),
		TilePlacement.make_target(Vector2i(1, 9), GridTypes.BeamColor.GREEN),
		TilePlacement.make_emitter(Vector2i(8, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_gate(Vector2i(8, 1), "gB", false),
		TilePlacement.make_switch(Vector2i(8, 2), "gC"),
		TilePlacement.make_blocker(Vector2i(8, 4)),
		TilePlacement.make_mirror(Vector2i(9, 11), GridTypes.MirrorOrientation.SLASH),
	]
