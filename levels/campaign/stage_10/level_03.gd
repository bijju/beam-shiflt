extends LevelData
## Campaign Level 93 — "Pre-Split Signal". FINAL CAMPAIGN BLOCK
## (Levels 91-100), EXTREME TIER. Built by extending Level 73's already-
## validated mutual-gate splitter geometry: a filter placed BEFORE the
## splitter recolors the beam for BOTH branches at once, but only
## actually matters for whichever branch has no filter of its OWN
## downstream to override it - color-order mastery that requires
## tracing each branch separately to know whether the shared upstream
## color survives or gets overwritten. See CAMPAIGN_DESIGN.md
## section 11m.

func _init() -> void:
	level_id = 3
	display_name = "Pre-Split Signal"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: filter (1,4) BLUE sits BEFORE the splitter, so BOTH branches start BLUE - but the straight branch has no filter of its own before its target, so it stays BLUE... except its one remaining filter (5,8) overwrites it to GREEN anyway, making the pre-split color a genuine red herring on that branch. The reflected branch's own first filter was removed entirely, yet its target still needs RED because its LAST filter (5,1) still overwrites whatever arrived - so the pre-split BLUE never survives on either branch, and the player must trace each branch's own downstream filters to realize this rather than assuming the shared upstream color carries through. Mutual-gate core identical to Level 73 (each branch's own switch opens the OTHER branch's gate). Straight branch (unconditional RIGHT off splitter (2,4)): mirror (3,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,1) instead - mirror (3,6) flips to BACKSLASH (RIGHT), mirror (4,6) flips to BACKSLASH (DOWN), mirror (4,8) flips to BACKSLASH (RIGHT), filter (5,8) GREEN (overwrites the pre-split BLUE), switch (6,8) [g1], through gate (7,8) [g2, opened by the reflected branch's switch], mirror (8,8) flips to BACKSLASH (DOWN) -> target A (8,10, GREEN). Reflected branch: splitter flips to SLASH (UP), mirror (2,0) flips to SLASH (RIGHT), mirror (4,0) flips to BACKSLASH (DOWN), mirror (4,1) flips to BACKSLASH (RIGHT), filter (5,1) RED (overwrites the pre-split BLUE), mirror (6,1) flips to BACKSLASH (DOWN), switch (6,3) [g2], through gate (6,4) [g1, opened by the straight branch's switch], mirror (6,6) flips to BACKSLASH (RIGHT) -> target B (7,6, RED). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,7) instead. INTENTIONAL DECOY: mirror (9,11) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 12
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_filter(Vector2i(1, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_splitter(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 7)),
		TilePlacement.make_blocker(Vector2i(3, 1)),
		TilePlacement.make_mirror(Vector2i(9, 11), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 8), GridTypes.BeamColor.GREEN),
		TilePlacement.make_switch(Vector2i(6, 8), "g1"),
		TilePlacement.make_gate(Vector2i(7, 8), "g2", false),
		TilePlacement.make_mirror(Vector2i(8, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 10), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 1), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(6, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 3), "g2"),
		TilePlacement.make_gate(Vector2i(6, 4), "g1", false),
		TilePlacement.make_mirror(Vector2i(6, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 6), GridTypes.BeamColor.RED),
	]
