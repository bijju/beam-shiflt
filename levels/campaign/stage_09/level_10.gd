extends LevelData
## Campaign Level 90 — "Full Circuit". MAJOR CAMPAIGN MILESTONE
## (hardest puzzle built so far). Built by extending Level 89's already-
## validated three-stage relay + double-portal + fourfold convergence:
## emitter 1's own very first step now ALSO passes through a gate opened
## only by a completely separate FIFTH emitter, giving emitter 1 the
## exact same two-independent-source convergence emitter 2 already had
## in Level 89 - symmetric depth on BOTH ends of the relay, not just
## one. Five emitters, two portals, a three-stage relay, and two
## independent converging gates, all resolved automatically by
## simulate_until_stable()'s multi-pass semantics with zero new engine
## code. See CAMPAIGN_DESIGN.md section 11l.

func _init() -> void:
	level_id = 10
	display_name = "Full Circuit"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical three-stage relay, double-portal structure, and emitter-4 convergence to Level 89 - but emitter 1's own very first step now ALSO passes through gate (1,2) [gF, opened only by a fifth, completely separate emitter], mirroring emitter 2's own gate (2,9) [gD, from emitter 4]. Both ends of the three-stage relay (emitter 1's start, emitter 2's start) now depend on an independent fourth/fifth source before the relay chain can even begin, while the relay's own internal chain (emitter 1 -> gate on emitter 2 -> emitter 2 -> gate on emitter 3 -> emitter 3 -> final gate on emitter 1) still resolves the same way it did in Level 87/88/89. Neither emitter 4 nor emitter 5 depends on anything downstream of themselves, so there is no circular deadlock - only two independent, symmetric convergences feeding into an otherwise-unchanged forward relay. Emitter 1 chain: through gate (1,2) [gF, opened by emitter 5], mirror (2,2) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (2,0) instead - switch (2,4) [gA], through gate (2,5) [gC], mirror (2,6) flips to BACKSLASH (RIGHT), mirror (3,6) flips to BACKSLASH (DOWN), mirror (3,7) flips to BACKSLASH (RIGHT), filter (5,7) BLUE, mirror (6,7) flips to BACKSLASH (DOWN), mirror (6,9) flips to BACKSLASH (RIGHT), into portal (7,9)/pair P -> exits (0,1) still moving RIGHT -> mirror (3,1) flips to BACKSLASH (DOWN) -> mirror (3,2) flips to BACKSLASH (RIGHT) -> target A (5,2, BLUE). Emitter 2 chain (identical to Level 89): through gate (2,9) [gD, opened by emitter 4], mirror (4,9) flips to BACKSLASH (DOWN), through gate (4,10) [gA], mirror (4,11) flips to BACKSLASH (RIGHT), mirror (5,11) flips to SLASH (UP), mirror (5,10) flips to SLASH (RIGHT), switch (6,10) [gB], into portal (7,10)/pair Q -> exits (0,11) still moving RIGHT -> mirror (1,11) flips to SLASH (UP) - if left at its authored BACKSLASH the beam runs DOWN and exits the grid immediately instead - filter (1,10) GREEN -> target B (1,9, GREEN). Emitter 3 (fires DOWN from (8,0), identical to Level 87/88/89, needs no mirror at all): through gate (8,1) [gB] -> switch (8,2) [gC] -> blocker (8,4) stops the beam there, harmlessly. Emitter 4 (fires LEFT from (9,5), identical to Level 89, needs no mirror at all): switch (4,5) [gD] trips as soon as the beam reaches it -> blocker (3,5) stops the beam there, harmlessly. Emitter 5 (fires DOWN from (9,6), a completely separate short chain with no mirror needed, confined to column 9 rows 5-9 - clear of emitter 4's own row 4): switch (9,11) [gF] trips as soon as the beam reaches it, then exits the grid off the bottom edge harmlessly. INTENTIONAL DECOY: mirror (0,0) is never touched by any beam in any configuration (solver-confirmed)."
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
		TilePlacement.make_emitter(Vector2i(9, 6), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_switch(Vector2i(9, 11), "gF"),
		TilePlacement.make_mirror(Vector2i(0, 0), GridTypes.MirrorOrientation.SLASH),
	]
