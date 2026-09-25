extends LevelData
## Campaign Level 100 — "Culmination". THE DEFINITIVE FINAL CAMPAIGN
## PUZZLE. Built by extending Level 90's already-validated three-stage
## relay + double-portal + symmetric-convergence geometry - the
## campaign's own prior milestone - with one genuine backward-reasoning
## touch (a fixed mirror the player must reason backward through, not
## just another rotatable piece). A first draft also tried gating
## emitter 4 behind emitter 1's own post-target continuation, which
## turned out to close the exact circular deadlock D69 warned about
## (emitter 1 needs emitter 3, emitter 3 needs emitter 2, emitter 2
## needs emitter 4, emitter 4 would have needed emitter 1's own
## completion) - caught immediately by the solver reporting UNSOLVABLE,
## removed rather than reworked, since Level 100 above all must remain
## fair and understandable. Deliberately NOT larger, NOT denser, and
## NOT padded in move count than Level 90 - the culmination comes from
## every mechanic taught across the whole 100-level campaign appearing
## at once in one coherent system: emitters, mirrors, a fixed mirror,
## portals, filters, switches, gates, a hazard, a blocker, a three-stage
## relay, symmetric converging gates, target continuation, and backward
## reasoning - with nothing decorative. See CAMPAIGN_DESIGN.md
## section 11m and DECISIONS.md D70.

func _init() -> void:
	level_id = 10
	display_name = "Culmination"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical three-stage relay to Level 87-90 (emitter 1's switch opens emitter 2's early gate; emitter 2's switch opens emitter 3's early gate; emitter 3's switch opens the final gate on emitter 1's own tail), identical double-portal structure and symmetric convergence (emitter 4 gates emitter 2's start, emitter 5 gates emitter 1's start) - but mirror (3,2), the last piece on emitter 1's post-portal approach, is now FIXED at BACKSLASH and cannot be rotated, so the player must reason backward from target A's position and the fixed mirror's one possible output to know which direction mirror (3,1) needs to send the beam, rather than treating every mirror as a free rotation. Emitter 1 chain: through gate (1,2) [gF, opened by emitter 5], mirror (2,2) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (2,0) instead - switch (2,4) [gA], through gate (2,5) [gC], mirror (2,6) flips to BACKSLASH (RIGHT), mirror (3,6) flips to BACKSLASH (DOWN), mirror (3,7) flips to BACKSLASH (RIGHT), filter (5,7) BLUE, mirror (6,7) flips to BACKSLASH (DOWN), mirror (6,9) flips to BACKSLASH (RIGHT), into portal (7,9)/pair P -> exits (0,1) still moving RIGHT -> mirror (3,1) flips to BACKSLASH (DOWN) - the player must infer this from the fixed mirror ahead, not from the target directly -> into the FIXED mirror (3,2) (BACKSLASH, RIGHT) -> target A (5,2, BLUE). Emitter 2 chain (identical to Level 89/90): through gate (2,9) [gD, opened by emitter 4], mirror (4,9) flips to BACKSLASH (DOWN), through gate (4,10) [gA], mirror (4,11) flips to BACKSLASH (RIGHT), mirror (5,11) flips to SLASH (UP), mirror (5,10) flips to SLASH (RIGHT), switch (6,10) [gB], into portal (7,10)/pair Q -> exits (0,11) still moving RIGHT -> mirror (1,11) flips to SLASH (UP) - if left at its authored BACKSLASH the beam runs DOWN and exits the grid immediately instead - filter (1,10) GREEN -> target B (1,9, GREEN). Emitter 3 (fires DOWN from (8,0), identical to Level 87-90, needs no mirror at all): through gate (8,1) [gB] -> switch (8,2) [gC] -> blocker (8,4) stops the beam there, harmlessly. Emitter 4 (fires LEFT from (9,5), identical to Level 89/90, needs no mirror at all): switch (4,5) [gD] trips as soon as the beam reaches it -> blocker (3,5) stops the beam there, harmlessly. Emitter 5 (fires DOWN from (9,6), a completely separate chain with one new forced bend, not present in Level 90): mirror (9,7) flips to SLASH (LEFT) - if left at its authored BACKSLASH the beam runs RIGHT and exits the grid immediately, and gF never opens - switch (8,7) [gF] -> blocker (7,7) stops the beam there, harmlessly, well clear of portal pair P. INTENTIONAL DECOY: mirror (0,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 12
	optimal_moves = 13
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_gate(Vector2i(1, 2), "gF", false),
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
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.BACKSLASH, false),
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
		TilePlacement.make_emitter(Vector2i(9, 6), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(9, 7), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(8, 7), "gF"),
		TilePlacement.make_blocker(Vector2i(7, 7)),
		TilePlacement.make_mirror(Vector2i(0, 0), GridTypes.MirrorOrientation.SLASH),
	]
