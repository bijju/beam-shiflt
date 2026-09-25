extends LevelData
## Campaign Level 78 — "Distant Corridor". Post-70 Levels 71-80,
## EXTREME ENTRY TIER. The same shared-physical-gate crossing proven in
## Level 72 (two emitters cross gate (4,5) from perpendicular
## directions, either switch opens it for both), but emitter 1's
## delivery now jumps through a portal into a completely separate
## corner of an expanded 10x10 board and bounces through three more
## mirrors before reaching its target - non-local portal reasoning
## layered on top of the shared-gate dependency. Built by extending
## Level 72's already-validated geometry only past its last mirror,
## leaving the shared gate crossing and the whole of emitter 2's chain
## byte-for-byte unchanged. See CAMPAIGN_DESIGN.md section 11k.

func _init() -> void:
	level_id = 8
	display_name = "Distant Corridor"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical shared-gate core to Level 72 (gate (4,5) is a single shared corridor crossed by both emitters from perpendicular directions; EITHER emitter's own switch opens it for both) - but emitter 1's beam, after clearing the gate and bouncing off mirror (5,5), is sent DOWN into a portal at (5,7) that jumps it clear across the board to (7,7), still moving DOWN, where three more mirrors bounce it RIGHT, DOWN, then LEFT into a relocated target in the opposite corner. This means the player cannot verify emitter 1's delivery by local inspection near the gate - they must trace the portal jump into an entirely separate region of the board and resolve three more orientation decisions there. Emitter 1 chain: mirror (1,5) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,3) instead - filter (1,6) RED, mirror (1,7) flips to BACKSLASH (RIGHT), switch (2,7) [g1], mirror (3,7) is ALREADY correctly authored at SLASH (RIGHT->UP, a genuine zero-move load-bearing piece), filter (3,6) BLUE (overwrites RED), mirror (3,5) flips to SLASH (UP->RIGHT), through the shared gate (4,5) -> mirror (5,5) flips to BACKSLASH (RIGHT->DOWN), through the harmless empty transit cell (5,6) shared with emitter 2, into portal (5,7)/pair A -> exits (7,7) still moving DOWN -> mirror (7,8) flips to SLASH->BACKSLASH (DOWN->RIGHT) -> mirror (8,8) flips to SLASH->BACKSLASH (RIGHT->DOWN) -> mirror (8,9) flips to BACKSLASH->SLASH (DOWN->LEFT) -> target A (7,9, BLUE). Emitter 2 (fires DOWN from (4,0), byte-for-byte identical to Level 72) chain: switch (4,1) [g1], mirror (4,2) flips to BACKSLASH (DOWN->RIGHT), mirror (5,2) flips to BACKSLASH (RIGHT->DOWN), filter (4,4) GREEN, mirror (5,3) flips to SLASH (DOWN->LEFT), mirror (4,3) flips to SLASH (LEFT->DOWN), through the SAME shared gate from the north -> mirror (4,6) flips to BACKSLASH (DOWN->RIGHT) -> target B (6,6, GREEN) (passing harmlessly through the shared transit cell (5,6) along the way, then continuing past its own target with nothing further in its way). INTENTIONAL DECOY: mirror (0,9) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 12
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 3)),
		TilePlacement.make_filter(Vector2i(1, 6), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(1, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(2, 7), "g1"),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(3, 6), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(4, 5), "g1", false),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(5, 7), "A"),
		TilePlacement.make_portal(Vector2i(7, 7), "A"),
		TilePlacement.make_mirror(Vector2i(7, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(8, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(8, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(7, 9), GridTypes.BeamColor.BLUE),
		TilePlacement.make_emitter(Vector2i(4, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_switch(Vector2i(4, 1), "g1"),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 4), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 6), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(0, 9), GridTypes.MirrorOrientation.SLASH),
	]
