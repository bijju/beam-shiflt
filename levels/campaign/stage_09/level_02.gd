extends LevelData
## Campaign Level 82 — "Crossed Corridors". EXTREME TIER (Levels 81-90).
## Two emitters run independent 3-filter-order color chains through
## fully disjoint lanes, converging at a mutual-looking gate dependency
## PLUS a third, completely separate emitter whose own short chain gates
## a mid-route cell on emitter 1's path - a genuine three-way
## convergence, not just a pairwise one. Each main beam also passes once
## through the OTHER beam's own target/transit cell, always with a
## mismatched color, confirmed inert. See CAMPAIGN_DESIGN.md section 11l.

func _init() -> void:
	level_id = 2
	display_name = "Crossed Corridors"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: emitter 1's own mid-chain now passes through gate (4,7) [g2, opened only by a completely separate third emitter], AND emitter 2's separate route depends on gate (6,11) [g1, opened by emitter 1's own switch (9,10), which emitter 1 can only reach after itself clearing gate (4,7)] - so emitter 2's dependency on emitter 1 is now transitively also a dependency on emitter 3. Emitter 1 chain: mirror (2,2) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (2,0) instead - filter (2,5) RED, mirror (2,6) flips to BACKSLASH (RIGHT), mirror (3,6) flips to BACKSLASH (DOWN), mirror (3,7) flips to BACKSLASH (RIGHT), through gate (4,7) [g2, opened by emitter 3], filter (5,7) GREEN (overwrites RED), mirror (6,7) flips to BACKSLASH (DOWN), filter (6,9) BLUE (overwrites GREEN), mirror (6,10) flips to BACKSLASH (RIGHT), passing harmlessly through (7,10) - emitter 2's own target cell, always BLUE there so it never matches emitter 2's required GREEN - into target A (8,10, BLUE), continues RIGHT past it into switch (9,10) [g1]. Emitter 2 chain: mirror (1,9) flips to BACKSLASH (DOWN), filter (1,10) RED, mirror (1,11) flips to BACKSLASH (RIGHT), filter (4,11) GREEN (overwrites RED), through gate (6,11) [g1, opened only by emitter 1's switch], mirror (7,11) flips to SLASH (UP) - if left at its authored BACKSLASH the beam runs DOWN and exits the grid, and the gate dependency becomes moot - into target B (7,10, GREEN), continues UP past it harmlessly through (7,7) - emitter 1's own empty transit cell - and exits the grid off the top edge. Emitter 3 (fires DOWN from (9,1), a completely separate short chain): mirror (9,2) flips to SLASH (LEFT) - if left at its authored BACKSLASH the beam runs RIGHT and exits the grid immediately, and g2 never opens - mirror (6,2) flips to SLASH (DOWN) - if left at its authored BACKSLASH the beam runs UP and exits the grid instead - switch (6,4) [g2] -> blocker (6,5) stops the beam there, harmlessly. INTENTIONAL DECOY: mirror (9,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 12
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(2, 0)),
		TilePlacement.make_filter(Vector2i(2, 5), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(4, 7), "g2", false),
		TilePlacement.make_filter(Vector2i(5, 7), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(6, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(6, 9), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(6, 10), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 10), GridTypes.BeamColor.BLUE),
		TilePlacement.make_switch(Vector2i(9, 10), "g1"),
		TilePlacement.make_emitter(Vector2i(0, 9), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(1, 10), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(1, 11), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 11), GridTypes.BeamColor.GREEN),
		TilePlacement.make_gate(Vector2i(6, 11), "g1", false),
		TilePlacement.make_mirror(Vector2i(7, 11), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(7, 10), GridTypes.BeamColor.GREEN),
		TilePlacement.make_emitter(Vector2i(9, 1), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(9, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(6, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(6, 4), "g2"),
		TilePlacement.make_blocker(Vector2i(6, 5)),
		TilePlacement.make_mirror(Vector2i(9, 0), GridTypes.MirrorOrientation.SLASH),
	]
