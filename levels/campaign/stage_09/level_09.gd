extends LevelData
## Campaign Level 89 — "Fourfold Relay". EXTREME MILESTONE
## (Levels 81-90). Built by extending Level 88's already-validated
## double-portal three-stage relay: emitter 2's early path now ALSO
## passes through a gate opened only by a completely separate FOURTH
## emitter, so the branch that used to depend only on emitter 1 (via the
## relay) now depends on two independent upstream sources at once - a
## genuine convergence layered on top of the relay, not a fourth relay
## stage (which would risk an actual circular dependency). Emitter 1's
## portal-exit tail also gains one more forced bend.
## See CAMPAIGN_DESIGN.md section 11l.

func _init() -> void:
	level_id = 9
	display_name = "Fourfold Relay"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical three-stage relay and double-portal structure to Level 88 - but emitter 2's very first step now passes through gate (2,9) [gD, opened only by a fourth, completely separate emitter], so emitter 2's own branch requires BOTH emitter 4 (immediately) and emitter 1 (via gate (4,10) [gA], reached later in the same branch) before it can even begin its own journey to the relay. This is deliberately a CONVERGENCE (two independent sources gating one branch), not a fourth relay stage - a genuine fourth stage (emitter 4's own switch gating something back on emitter 1 or emitter 3) would risk an actual circular deadlock, since emitter 3's gate is already the final link back to emitter 1. Emitter 1 chain (identical to Level 88's portal jump, with one more forced bend before its target): mirror (2,2) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (2,0) instead - switch (2,4) [gA], through gate (2,5) [gC], mirror (2,6) flips to BACKSLASH (RIGHT), mirror (3,6) flips to BACKSLASH (DOWN), mirror (3,7) flips to BACKSLASH (RIGHT), filter (5,7) BLUE, mirror (6,7) flips to BACKSLASH (DOWN), mirror (6,9) flips to BACKSLASH (RIGHT), into portal (7,9)/pair P -> exits (0,1) still moving RIGHT -> mirror (3,1) flips to BACKSLASH (DOWN) -> mirror (3,2) flips to BACKSLASH (RIGHT) -> target A (5,2, BLUE). Emitter 2 chain: through gate (2,9) [gD, opened by emitter 4], mirror (4,9) flips to BACKSLASH (DOWN), through gate (4,10) [gA, opened by emitter 1], mirror (4,11) flips to BACKSLASH (RIGHT), mirror (5,11) flips to SLASH (UP), mirror (5,10) flips to SLASH (RIGHT), switch (6,10) [gB], into portal (7,10)/pair Q -> exits (0,11) still moving RIGHT -> mirror (1,11) flips to SLASH (UP) - if left at its authored BACKSLASH the beam runs DOWN and exits the grid immediately instead - filter (1,10) GREEN -> target B (1,9, GREEN). Emitter 3 (fires DOWN from (8,0), identical to Level 87/88, needs no mirror at all): through gate (8,1) [gB] -> switch (8,2) [gC] -> blocker (8,4) stops the beam there, harmlessly. Emitter 4 (fires LEFT from (9,5), a completely separate short chain with no mirror needed): switch (4,5) [gD] trips as soon as the beam reaches it -> blocker (3,5) stops the beam there, harmlessly, well clear of gate (2,5)'s column. INTENTIONAL DECOY: mirror (9,11) is never touched by any beam in any configuration (solver-confirmed). A first draft placed target A at (5,3), one row off from where the beam actually travels after its two new bends (row 2, not row 3) - the solver correctly reported UNSOLVABLE, caught before any manual re-trace was needed, and fixed by moving the target to (5,2); see DECISIONS.md D69."
	is_campaign_level = true
	grid_width = 10
	grid_height = 12
	optimal_moves = 13
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
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 2), GridTypes.BeamColor.BLUE),
		TilePlacement.make_emitter(Vector2i(0, 9), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_gate(Vector2i(2, 9), "gD", false),
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
		TilePlacement.make_emitter(Vector2i(9, 5), GridTypes.Direction.LEFT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_switch(Vector2i(4, 5), "gD"),
		TilePlacement.make_blocker(Vector2i(3, 5)),
		TilePlacement.make_mirror(Vector2i(9, 11), GridTypes.MirrorOrientation.SLASH),
	]
