extends LevelData
## Campaign Level 25 — "Bottleneck". DIFFICULTY REWORK PASS 2, block finale.
## A splitter feeds two symmetric, winding chains (one to each of two
## required targets); the reflected branch's orientation is punished by a
## hazard if wrong, not just a miss. First level in the block requiring
## the player to plan both branches before touching anything.
## See CAMPAIGN_DESIGN.md section 11f (Pass 2).
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board changed 9x9 -> 7x8 via an
## order-preserving coordinate remap on BOTH axes (see DECISIONS.md D73) -
## columns compacted from 9 to 7 (only 6 distinct columns were ever used,
## one spare kept for spacing since this is the block finale with two
## fully separate branches; cell_size rises to 124px vs the old 96px, a
## +29% readability gain). Identical puzzle topology/solution - the two
## branches remain on fully disjoint rows/columns by construction, since
## the remap preserves distinctness exactly. Solver-confirmed
## optimal_moves unchanged (6).

func _init() -> void:
	level_id = 5
	display_name = "Bottleneck"
	stage = "Split"
	developer_notes = "DESIGN INTENT: two required targets, each at the end of its own fully separate mirror chain off a shared splitter (the two chains never share a row or column, by construction, so there is no accidental shortcut between them) - the player has to plan both branches (6 total flips) before making a move. Straight branch (unconditional RIGHT off splitter (1,4)): mirror (4,4) flips to BACKSLASH (DOWN) -> mirror (4,5) flips to BACKSLASH (RIGHT) -> mirror (6,5) flips to BACKSLASH (DOWN) -> fixed mirror (6,7, SLASH, DOWN->LEFT) -> target A (5,7, WHITE). Reflected branch: splitter flips to SLASH (UP) -> mirror (1,0) flips to SLASH (RIGHT) -> mirror (2,0) flips to BACKSLASH (DOWN) -> fixed mirror (2,2, BACKSLASH, DOWN->RIGHT) -> target B (5,2, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch goes DOWN into the hazard at (1,5) instead - a real punishment, not a geometry miss. INTENTIONAL DECOY: mirror (6,4) sits in the same row as the splitter's straight branch, plausible as an early turn point, but no beam in any configuration ever reaches it (solver-confirmed) - an earlier draft placed target B directly in another mirror's column and the solver caught a 2-move shortcut through that accidental collinearity; this version keeps the two branches on fully disjoint rows/columns."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 5)),
		TilePlacement.make_mirror(Vector2i(6, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 7), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_target(Vector2i(5, 7), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(5, 2), GridTypes.BeamColor.WHITE),
	]
