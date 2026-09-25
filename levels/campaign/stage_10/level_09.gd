extends LevelData
## Campaign Level 99 — "Penultimate Verdict". FINAL CAMPAIGN BLOCK
## (Levels 91-100), PENULTIMATE CHALLENGE TIER. Built by extending
## Level 97's already-validated mutual-gate/portal/global-late-gate
## geometry: the reflected branch's very first step now ALSO passes
## through a gate opened only by a completely separate FOURTH emitter -
## with three targets already active-or-dark depending on subtle,
## separate dependencies, a player who solves two of the three easily
## can mistake the board for nearly finished while the fourth,
## unrelated-looking emitter is the one piece they haven't noticed yet.
## See CAMPAIGN_DESIGN.md section 11m.

func _init() -> void:
	level_id = 9
	display_name = "Penultimate Verdict"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical mutual-gate/portal/global-late-gate core to Level 97 (three independent beam sources - the splitter's two branches and a third emitter - all ultimately depending on gate g3, opened only by the straight branch's post-target continuation) - but the reflected branch's very first step now ALSO passes through gate (2,1) [g4, opened only by a fourth, completely separate emitter]. With three targets in play and two of them (A and C) sharing dependency on the same late gate g3, a player who solves the straight branch and notices g3's effect on target C can plausibly believe the board is fully understood - while the reflected branch's target B additionally depends on a fourth emitter they may not have traced at all, since it gates the very FIRST cell of the reflected branch rather than its final approach. Straight branch, third emitter: byte-for-byte identical to Level 97 (see its own notes for the full trace). Reflected branch: through gate (2,1) [g4, opened by the fourth emitter], mirror (2,0) flips to SLASH (RIGHT), filter (3,0) GREEN, mirror (4,0) flips to BACKSLASH (DOWN), mirror (4,1) flips to BACKSLASH (RIGHT), filter (5,1) RED (overwrites GREEN), mirror (6,1) flips to BACKSLASH (DOWN), switch (6,2) [g2], through gate (6,4) [g1, opened by the straight branch's switch], mirror (6,5) flips to BACKSLASH (RIGHT), through gate (7,5) [g3, opened by the straight branch's post-target continuation], mirror (8,5) flips to BACKSLASH (DOWN) -> target B (8,6, RED). Fourth emitter (fires DOWN from (9,0), a completely separate short chain with no mirror needed): switch (9,1) [g4] trips as soon as the beam reaches it -> blocker (9,2) stops the beam there, harmlessly. INTENTIONAL DECOY: mirror (0,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 12
	optimal_moves = 14
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
		TilePlacement.make_gate(Vector2i(2, 1), "g4", false),
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
		TilePlacement.make_emitter(Vector2i(5, 11), GridTypes.Direction.UP, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(6, 6), "g3", false),
		TilePlacement.make_target(Vector2i(7, 6), GridTypes.BeamColor.WHITE),
		TilePlacement.make_emitter(Vector2i(9, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_switch(Vector2i(9, 1), "g4"),
		TilePlacement.make_blocker(Vector2i(9, 2)),
	]
