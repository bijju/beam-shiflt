extends LevelData
## Campaign Level 97 — "Triple Verdict". FINAL CAMPAIGN BLOCK
## (Levels 91-100), FINAL-EXAM TIER (global dependency). Built by
## extending Level 92's already-validated mutual-gate/portal/delayed-
## consequence geometry: a completely separate THIRD emitter's own
## target now ALSO requires gate g3 - the same late gate the reflected
## branch already needed, opened only by the straight branch's post-
## target continuation. Three independent beam sources (the splitter's
## two branches plus this third emitter) all appear unrelated, but all
## ultimately depend on the same one late gate.
## See CAMPAIGN_DESIGN.md section 11m.

func _init() -> void:
	level_id = 7
	display_name = "Triple Verdict"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical mutual-gate/portal/delayed-consequence core to Level 92 - but a completely separate third emitter's own target now ALSO passes through gate (6,6) [g3, the exact same gate id already gating the reflected branch's approach at (7,5)]. All three beam sources - the splitter's straight branch, its reflected branch, and this third emitter - look like they belong to unrelated subsystems, but none of the two gated ones can complete until the straight branch's delivery travels all the way past its own target to the distant switch at (9,11). Straight branch and reflected branch: byte-for-byte identical to Level 92 (see its own notes for the full trace). Third emitter (fires UP from (5,11), a completely separate chain sharing nothing but the late gate): mirror (5,6) flips to SLASH (RIGHT) - if left at its authored BACKSLASH the beam runs LEFT instead, wandering harmlessly through the straight branch's own filter (4,6) and out the west edge, never reaching the gate - through gate (6,6) [g3, opened only by the straight branch's post-target continuation] -> target C (7,6, WHITE). INTENTIONAL DECOY: mirror (0,0) is never touched by any beam in any configuration (solver-confirmed)."
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
	]
