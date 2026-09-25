extends LevelData
## Campaign Level 22 — "Detour". DIFFICULTY REWORK PASS 2.
## A mid-chain filter permanently recolors the beam before a mandatory
## portal hop; the portal's exit direction still has to be threaded through
## three more mirrors to reach a color-matched target. A rotatable decoy
## sits in a column that looks relevant but is never touched.
## See CAMPAIGN_DESIGN.md section 11f (Pass 2).
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board changed 7x7 -> 6x7 via an
## order-preserving coordinate remap on BOTH axes (see DECISIONS.md D73) -
## columns compacted from 7 to 6 (6 distinct columns were already in use,
## so this is the tightest safe compaction; cell_size rises to 145px vs
## the old 124px). Identical puzzle topology/solution, solver-confirmed
## optimal_moves unchanged (6).

func _init() -> void:
	level_id = 2
	display_name = "Detour"
	stage = "Split"
	developer_notes = "DESIGN INTENT: portal transit is one link in a 6-mirror chain, not a shortcut - the beam's color (fixed by an early filter) and the portal's preserved exit direction both have to be tracked all the way to the target. Chain: emitter (0,0) RIGHT WHITE -> mirror (1,0) flips to BACKSLASH (DOWN) -> passes filter (1,2) which permanently recolors the beam RED -> mirror (1,4) flips to BACKSLASH (RIGHT) into portal (2,4)/pair A -> exits portal (4,1) still moving RIGHT -> mirror (5,1) flips to BACKSLASH (DOWN) -> mirror (5,5) flips to SLASH (LEFT) -> mirror (2,5) flips to SLASH (DOWN) -> mirror (2,6) flips to BACKSLASH (RIGHT) -> target (3,6, RED). INTENTIONAL DECOY: mirror (1,6) sits in the same column as the filter/mirror-(1,4) junction, plausible as 'the beam continues straight down' if the player misreads mirror (1,4), but the beam never reaches it (solver-confirmed)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(1, 2), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(1, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(2, 4), "A"),
		TilePlacement.make_portal(Vector2i(4, 1), "A"),
		TilePlacement.make_mirror(Vector2i(5, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(3, 6), GridTypes.BeamColor.RED),
	]
