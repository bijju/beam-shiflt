extends LevelData
## Campaign Level 24 — "Standoff". DIFFICULTY REWORK PASS 2.
## Splitter/switch/gate dependency: the reflected branch's ONLY job is to
## trip a switch that opens a gate blocking the straight branch's own
## route to the target. Wrong splitter orientation both misses the switch
## AND runs into a hazard - a real, doubled consequence.
## See CAMPAIGN_DESIGN.md section 11f (Pass 2).
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board changed 8x8 -> 6x7 via an
## order-preserving coordinate remap on BOTH axes (see DECISIONS.md D73) -
## columns compacted from 8 to 6 (only 6 distinct columns were ever used;
## cell_size rises to 145px vs the old 109px, a +33% readability gain).
## Identical puzzle topology/solution, solver-confirmed optimal_moves
## unchanged (6).

func _init() -> void:
	level_id = 4
	display_name = "Standoff"
	stage = "Split"
	developer_notes = "DESIGN INTENT: the splitter's straight branch is physically blocked by a closed gate until the reflected branch (a structurally separate detour) crosses the switch that opens it - both must be configured correctly at once; simulate_until_stable resolves the switch->gate dependency within a single evaluation once the board is wired right. Chain: emitter (0,2) RIGHT WHITE -> mirror (1,2) flips to BACKSLASH (DOWN) -> mirror (1,5) flips to BACKSLASH (RIGHT) into splitter (2,5). Splitter flips to SLASH: reflected branch goes UP through mirror (2,3) [flip to SLASH, RIGHT] -> mirror (3,3) [flip to SLASH, UP] -> switch (3,0) (gate_id g1) -> exits board, no target needed there. Straight branch (unconditional) continues RIGHT to gate (4,5, g1, closed) - blocked until the switch opens it - then mirror (5,5) flips to BACKSLASH (DOWN) -> target (5,6, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch goes DOWN into the hazard at (2,6) instead of the switch, so the gate never opens AND the level fails outright. INTENTIONAL DECOY: mirror (0,5) is never reached by any beam in any solved configuration (solver-confirmed) - it only sits on the path of the already-failing wrong-mirror-(1,5) branch."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(0, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_splitter(Vector2i(2, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 6)),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(3, 0), "g1"),
		TilePlacement.make_gate(Vector2i(4, 5), "g1", false),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 6), GridTypes.BeamColor.WHITE),
	]
