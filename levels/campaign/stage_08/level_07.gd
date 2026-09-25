extends LevelData
## Campaign Level 77 — "Distant Splitter". Post-70 Levels 71-80, MASTER+
## TIER. A single splitter's two branches gate EACH OTHER (same mutual
## switch/gate dependency proven in Level 73), but the straight branch's
## final leg now jumps through a portal to a completely different corner
## of the board before reaching its target - non-local portal reasoning
## layered on top of the mutual-gate dependency. Built by extending
## Level 73's already-validated geometry only past its last mirror,
## leaving the entire mutual-gate core and the whole reflected branch
## byte-for-byte unchanged. See CAMPAIGN_DESIGN.md section 11k.

func _init() -> void:
	level_id = 7
	display_name = "Distant Splitter"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical mutual-gate core to Level 73 (each branch's own switch opens the OTHER branch's gate, resolved across two simulation passes) - but the straight branch's beam, after clearing gate g2, is redirected DOWN into a portal at (8,9) that jumps it clear across the board to (1,10), still moving DOWN, where a final mirror sends it right along the bottom row to a relocated target. This means the player cannot verify the straight branch's delivery by local inspection near the gate - they must trace the portal jump to a totally separate region. Straight branch (unconditional RIGHT off splitter (2,4)): mirror (3,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,1) instead - mirror (3,5) flips to BACKSLASH (RIGHT), mirror (4,5) flips to BACKSLASH (DOWN), filter (4,6) RED, mirror (4,7) flips to BACKSLASH (RIGHT), filter (5,7) BLUE (overwrites RED), switch (6,7) [g1], through gate (7,7) [g2, opened by the reflected branch's switch], mirror (8,7) flips to BACKSLASH (DOWN), into portal (8,9)/pair A -> exits (1,10) still moving DOWN -> mirror (1,11) flips to BACKSLASH (RIGHT) -> target A (8,11, BLUE). Reflected branch (byte-for-byte identical to Level 73): splitter flips to SLASH (UP), mirror (2,0) flips to SLASH (RIGHT), filter (3,0) GREEN, mirror (4,0) flips to BACKSLASH (DOWN), mirror (4,1) flips to BACKSLASH (RIGHT), filter (5,1) RED (overwrites GREEN), mirror (6,1) flips to BACKSLASH (DOWN), switch (6,2) [g2], through gate (6,4) [g1, opened by the straight branch's switch], mirror (6,5) flips to BACKSLASH (RIGHT) -> target B (7,5, RED). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,6) instead. INTENTIONAL DECOY: mirror (9,11) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 12
	optimal_moves = 12
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 6)),
		TilePlacement.make_blocker(Vector2i(3, 1)),
		TilePlacement.make_mirror(Vector2i(9, 11), GridTypes.MirrorOrientation.SLASH),
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
	]
