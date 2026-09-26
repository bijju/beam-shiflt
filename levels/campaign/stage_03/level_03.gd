extends LevelData
## Campaign Level 23 — "Misdirect". DIFFICULTY REWORK PASS 2.
## Backward reasoning through two chained fixed mirrors, plus a false
## route that genuinely lights up a non-required decoy target of the
## wrong color - a false confirmation that looks like a solve but isn't.
## See CAMPAIGN_DESIGN.md section 11f (Pass 2).
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board changed 7x7 -> 6x7 via an
## order-preserving coordinate remap on BOTH axes (see DECISIONS.md D73) -
## columns compacted from 7 to 6 (cell_size rises to 145px vs the old
## 124px). Identical puzzle topology/solution, solver-confirmed
## optimal_moves unchanged (5).

func _init() -> void:
	level_id = 3
	display_name = "Misdirect"
	stage = "Split"
	developer_notes = "DESIGN INTENT: the two fixed mirrors at (4,4) and (5,4) are visible from the start - the player must reason backward from target A (5,0, RED) through both of them to work out that the beam must arrive at (4,4) moving DOWN, which is what determines every rotatable mirror upstream. Chain: emitter (0,0) RIGHT RED -> mirror (2,0) flips to BACKSLASH (DOWN) -> mirror (2,2) flips to BACKSLASH (RIGHT) -> mirror (3,2) flips to BACKSLASH (DOWN) -> mirror (3,4) flips to BACKSLASH (RIGHT) -> mirror (4,4) [rotatable in this chain, see tile list] flips to BACKSLASH (DOWN) -> fixed mirror (4,6, BACKSLASH, DOWN->RIGHT) -> fixed mirror (5,6, SLASH, RIGHT->UP) -> target (5,0, RED). FALSE CONFIRMATION: if mirror (2,2) is left at its authored SLASH, the beam is deflected LEFT through filter (1,2) (which recolors it WHITE) into non-required target (0,2, WHITE) - it visibly lights up, but the REQUIRED red target never does. No decoys - every rotatable piece is load-bearing (solver-confirmed)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(1, 2), GridTypes.BeamColor.WHITE),
		TilePlacement.make_target(Vector2i(0, 2), GridTypes.BeamColor.WHITE, false),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_target(Vector2i(5, 0), GridTypes.BeamColor.RED),
	]
