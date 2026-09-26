extends LevelData
## Campaign Level 87 — "Triple Relay". EXTREME+ TIER (Levels 81-90).
## The FIRST genuine three-stage relay in the campaign: emitter 1's
## switch (unconditionally reachable, before any gate on its own path)
## opens emitter 2's early gate; only then can emitter 2's own switch
## open emitter 3's early gate; only then can emitter 3's own switch
## open the FINAL gate blocking emitter 1's own tail. A true forward
## chain (never a simulation cycle - each switch is always reachable
## before the gate that depends on the PREVIOUS link), resolved over 4
## simulation passes, extending Level 70/76's two-stage relay to three
## emitters for the first time. Each emitter's path is kept in fully
## disjoint rows/columns from the other two (a first draft that let two
## emitters share column 2 produced an unintended shortcut bypassing the
## whole relay - see CAMPAIGN_DESIGN.md section 11l and DECISIONS.md
## D69 for the rejected draft).

func _init() -> void:
	level_id = 7
	display_name = "Triple Relay"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: switch (1,3) [gA] is reachable unconditionally on emitter 1's own path (nothing gates it), so it always fires in pass 1, opening gate (3,8) [gA] on emitter 2's path. Only then can emitter 2 reach switch (5,8) [gB], opening gate (7,1) [gB] on emitter 3's path. Only then can emitter 3 reach switch (7,2) [gC], opening the FINAL gate (1,4) [gC] on emitter 1's OWN tail - so emitter 1 cannot complete its own route until a chain reaction through two other, otherwise-unrelated emitters has fully resolved. Resolves over 4 simulate_until_stable() passes. Emitter 1 chain (confined to columns 2-8, rows 0-7, never sharing a cell with emitter 2 or 3): mirror (1,2) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,0) instead - switch (1,3) [gA], through gate (1,4) [gC], mirror (1,5) flips to BACKSLASH (RIGHT), mirror (2,5) flips to BACKSLASH (DOWN), mirror (2,6) flips to BACKSLASH (RIGHT), filter (4,6) BLUE, mirror (5,6) flips to BACKSLASH (DOWN), mirror (5,7) flips to BACKSLASH (RIGHT) -> target A (7,7, BLUE). Emitter 2 chain (confined to columns 4-8, rows 7-9, never sharing a cell with emitter 1 or 3): mirror (3,7) flips to BACKSLASH (DOWN), through gate (3,8) [gA], mirror (3,9) flips to BACKSLASH (RIGHT), mirror (4,9) flips to SLASH (UP), mirror (4,8) flips to SLASH (RIGHT), switch (5,8) [gB], filter (6,8) GREEN -> target B (7,8, GREEN). Emitter 3 (fires DOWN from (7,0), confined to column 8 rows 0-3, never sharing a cell with emitter 1 or 2): through gate (7,1) [gB] -> switch (7,2) [gC] -> blocker (7,3) stops the beam there, harmlessly. Emitter 3 needs no mirror at all - once gate gB opens, its straight path does the rest automatically, matching the 'silent, always-on relay link' pattern used for the third emitter in Level 81. A first draft placed emitter 1 and emitter 2's mirrors in the SAME column (2), and when both were left at their unflipped default orientation, emitter 2's beam bent directly into emitter 1's own downstream chain and reached both targets in 5 moves without ever needing the relay - rebuilt with every emitter's entire path (not just its target) confirmed to occupy disjoint rows/columns from both others; see DECISIONS.md D69. INTENTIONAL DECOY: mirror (8,9) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 10
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 0)),
		TilePlacement.make_switch(Vector2i(1, 3), "gA"),
		TilePlacement.make_gate(Vector2i(1, 4), "gC", false),
		TilePlacement.make_mirror(Vector2i(1, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 6), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_emitter(Vector2i(0, 7), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(3, 8), "gA", false),
		TilePlacement.make_mirror(Vector2i(3, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 8), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(5, 8), "gB"),
		TilePlacement.make_filter(Vector2i(6, 8), GridTypes.BeamColor.GREEN),
		TilePlacement.make_target(Vector2i(7, 8), GridTypes.BeamColor.GREEN),
		TilePlacement.make_emitter(Vector2i(7, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_gate(Vector2i(7, 1), "gB", false),
		TilePlacement.make_switch(Vector2i(7, 2), "gC"),
		TilePlacement.make_blocker(Vector2i(7, 3)),
		TilePlacement.make_mirror(Vector2i(8, 9), GridTypes.MirrorOrientation.SLASH),
	]
