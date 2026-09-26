extends LevelData
## Campaign Level 21 — "Crossfire". DIFFICULTY REWORK PASS 2.
## Splitter dual-branch where the reflected branch's orientation is a real,
## punished decision (wrong orientation runs the beam into a hazard, not a
## harmless miss) while the straight branch needs its own downstream mirror.
## See CAMPAIGN_DESIGN.md section 11f (Pass 2).
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board changed 7x7 -> 6x7 via an
## order-preserving coordinate remap on BOTH axes (see DECISIONS.md D73) -
## columns compacted from 7 to 6 (only 5 distinct columns were ever used,
## and 6 columns brings cell_size up to the project's MIN_TOUCH_TARGET,
## 145px vs the old 124px) while rows grew to fill the portrait height.
## Identical puzzle topology/solution, solver-confirmed optimal_moves
## unchanged (5).

func _init() -> void:
	level_id = 1
	display_name = "Crossfire"
	stage = "Split"
	developer_notes = "DESIGN INTENT: the splitter's straight branch and reflected branch both feed a required target, and the reflected branch's orientation is punished (not just a harmless miss) if wrong. Entry chain: mirror (1,0) must flip to BACKSLASH (sends the beam DOWN), mirror (1,4) must flip to BACKSLASH (sends it RIGHT) into splitter (3,4). Splitter must flip to BACKSLASH: the straight (unconditional) branch continues RIGHT to mirror (5,4), which must flip to SLASH to send it UP into target A (5,0, WHITE); the reflected branch goes DOWN (BACKSLASH) into mirror (3,6), which must flip to SLASH to send it LEFT into target B (1,6, WHITE). If the splitter is left at its authored SLASH, the reflected branch goes UP instead and runs straight into the hazard at (3,2) - a real punishment, not a geometry miss. INTENTIONAL DECOY: mirror (4,6) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_splitter(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(3, 2)),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(5, 0), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(1, 6), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.SLASH),
	]
