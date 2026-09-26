extends LevelData
## Campaign Level 80 — "Full Convergence". MAJOR CAMPAIGN MILESTONE.
## Post-70 Levels 71-80, the hardest puzzle built so far - not by grid
## size or move count, but by convergence depth: ONE target (A) is
## gated by THREE independent sources (the splitter's own mutual g1/g2
## dependency, a third emitter's short chain via g3, and the reflected
## branch's own post-target delayed consequence via g4) all resolved
## automatically across multiple simulation passes, plus a portal jump
## and a genuine cross-system coupling (the third emitter's own gate is
## itself opened by the straight branch's switch, so even the
## "independent" third source is not really independent). Built by
## extending Level 79's already-validated geometry, leaving the mutual-
## gate core, the portal jump, and the third emitter's own 2-mirror
## chain byte-for-byte unchanged. See CAMPAIGN_DESIGN.md section 11k.

func _init() -> void:
	level_id = 10
	display_name = "Full Convergence"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: target A now requires FOUR things to all be true at once, each opened by a different part of the board, resolved automatically by simulate_until_stable's multi-pass evaluation: (1) gate (7,7) [g2, opened by the reflected branch's own switch (6,2)] on the straight branch's early approach, exactly as in Level 77/79; (2) the portal jump from (8,9) to (1,10), exactly as in Level 77/79; (3) gate (3,11) [g3, opened by the third emitter's switch (8,2)] on the tail, exactly as in Level 79; (4) a NEW gate (6,11) [g4, opened by the reflected branch's OWN post-target delayed consequence] later on the same tail. On top of this, the third emitter is no longer a free-standing side puzzle: its own beam must now first pass through a NEW gate (9,1) [g1, opened by the SAME straight-branch switch (6,7) that also opens g2's counterpart-in-spirit] before it can even reach its mirror at (9,2) - so what looked like an independent third source in Level 79 is now provably coupled to the rest of the board, not just adjacent to it. New reflected-branch delayed consequence: after activating target B (7,5, RED) the beam continues RIGHT (targets do not stop beams) through the empty transit cell (8,4) into mirror (9,5), flips to BACKSLASH (RIGHT->DOWN) - if left at its authored SLASH the beam runs UP and never reaches the switch - into switch (9,6) [g4], then continues harmlessly down column 9 off the bottom edge. New third-emitter coupling: emitter (9,0) fires DOWN through gate (9,1) [g1, opened by switch (6,7) on the straight branch - the same switch that also opens gate (7,7) for the straight branch's own beam], then continues exactly as in Level 79 (mirror (9,2) flips to SLASH, switch (8,2) [g3], decoy mirror (7,2)). Splitter core, portal jump, and third-emitter mirror chain are otherwise byte-for-byte identical to Level 79. If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,6) instead. INTENTIONAL DECOYS: mirror (0,0) and mirror (7,2) are never load-bearing in any configuration (solver-confirmed)."
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
		TilePlacement.make_gate(Vector2i(3, 11), "g3", false),
		TilePlacement.make_gate(Vector2i(6, 11), "g4", false),
		TilePlacement.make_target(Vector2i(8, 11), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(3, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 1), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(6, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 2), "g2"),
		TilePlacement.make_gate(Vector2i(6, 4), "g1", false),
		TilePlacement.make_mirror(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 5), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(9, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(9, 6), "g4"),
		TilePlacement.make_emitter(Vector2i(9, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_gate(Vector2i(9, 1), "g1", false),
		TilePlacement.make_mirror(Vector2i(9, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(8, 2), "g3"),
		TilePlacement.make_mirror(Vector2i(7, 2), GridTypes.MirrorOrientation.SLASH),
	]
