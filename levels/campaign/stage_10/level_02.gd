extends LevelData
## Campaign Level 92 — "Delayed Verdict". FINAL CAMPAIGN BLOCK
## (Levels 91-100), MASTER+ TIER. Built by extending Level 77's already-
## validated mutual-gate/portal geometry: the straight branch's target
## continuation (targets do not stop beams) now trips a switch that
## gates the reflected branch's OWN final approach, in addition to the
## mutual gate the two branches already share - a genuine near-solution
## trap, since a player who only solves the mutual-gate dependency will
## see NEITHER target light up until they also notice the far-away
## continuation switch. See CAMPAIGN_DESIGN.md section 11m.

func _init() -> void:
	level_id = 2
	display_name = "Delayed Verdict"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical mutual-gate core to Level 73/77 (each branch's own switch opens the OTHER branch's gate) - but the reflected branch's final approach now ALSO passes through a new gate (7,5) [g3], which only opens once the straight branch's delivery continues PAST its own target and reaches a distant switch at (9,11). A player who wires both branches' mutual gate correctly will see the straight branch's target light up, but the reflected branch will stay dark - looking like a near-complete, almost-working board - until they trace the straight branch's beam past its own target to the far corner switch. Straight branch (unconditional RIGHT off splitter (2,4), identical to Level 77 up to its own target): mirror (3,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,1) instead - mirror (3,5) flips to BACKSLASH (RIGHT), mirror (4,5) flips to BACKSLASH (DOWN), filter (4,6) RED, mirror (4,7) flips to BACKSLASH (RIGHT), filter (5,7) BLUE (overwrites RED), switch (6,7) [g1], through gate (7,7) [g2, opened by the reflected branch's switch], mirror (8,7) flips to BACKSLASH (DOWN), into portal (8,9)/pair A -> exits (1,10) still moving DOWN -> mirror (1,11) flips to BACKSLASH (RIGHT) -> target A (8,11, BLUE), continues RIGHT past it into switch (9,11) [g3]. Reflected branch: splitter flips to SLASH (UP), mirror (2,0) flips to SLASH (RIGHT), filter (3,0) GREEN, mirror (4,0) flips to BACKSLASH (DOWN), mirror (4,1) flips to BACKSLASH (RIGHT), filter (5,1) RED (overwrites GREEN), mirror (6,1) flips to BACKSLASH (DOWN), switch (6,2) [g2], through gate (6,4) [g1, opened by the straight branch's switch], mirror (6,5) flips to BACKSLASH (RIGHT), through gate (7,5) [g3, opened by the straight branch's post-target continuation], mirror (8,5) flips to BACKSLASH (DOWN) -> target B (8,6, RED). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,6) instead. INTENTIONAL DECOY: mirror (0,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 12
	optimal_moves = 13
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 6)),
		TilePlacement.make_blocker(Vector2i(3, 1)),
		TilePlacement.make_mirror(Vector2i(0, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 6), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(4, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_switch(Vector2i(6, 7), "g1"),
		TilePlacement.make_gate(Vector2i(7, 7), "g2", false),
		TilePlacement.make_mirror(Vector2i(8, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(8, 9), "A"),
		TilePlacement.make_portal(Vector2i(1, 10), "A"),
		TilePlacement.make_mirror(Vector2i(1, 11), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 11), GridTypes.BeamColor.BLUE),
		TilePlacement.make_switch(Vector2i(9, 11), "g3"),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(3, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 1), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(6, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 2), "g2"),
		TilePlacement.make_gate(Vector2i(6, 4), "g1", false),
		TilePlacement.make_mirror(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(7, 5), "g3", false),
		TilePlacement.make_mirror(Vector2i(8, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 6), GridTypes.BeamColor.RED),
	]
