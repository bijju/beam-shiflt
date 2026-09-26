extends LevelData
## Campaign Level 26 — "Labyrinth". DIFFICULTY REWORK PASS 2.
## Genuine cross-branch dependency: a single FIXED shared mirror is hit by
## both the splitter's straight branch (arriving RIGHT) and its reflected
## branch (arriving DOWN, after a long separate loop) - each branch needs
## its own 4-mirror approach chain wired correctly before the shared
## mirror's single fixed orientation can route both beams to their targets.
## See CAMPAIGN_DESIGN.md section 11f (Pass 2).

func _init() -> void:
	level_id = 6
	display_name = "Labyrinth"
	stage = "Split"
	developer_notes = "DESIGN INTENT: the fixed mirror at (5,2) is visible from the start - the player must recognize BOTH branches are routed to converge on it from perpendicular directions (straight branch arrives RIGHT, reflected branch arrives DOWN after looping up and over), and that its single BACKSLASH orientation happens to serve both (RIGHT->DOWN for target A, DOWN->RIGHT for target B) - a wrong approach direction on either branch misses entirely, it doesn't corrupt the other branch. Straight branch (unconditional RIGHT off splitter (1,2), via a rectangular detour): mirror (3,2) flips to BACKSLASH (DOWN), mirror (3,5) flips to BACKSLASH (RIGHT), mirror (4,5) flips to SLASH (UP), mirror (4,2) flips to SLASH (RIGHT), into fixed mirror (5,2) -> DOWN -> target A (5,7, WHITE). Reflected branch: splitter flips to SLASH (UP) -> mirror (1,0) flips to SLASH (RIGHT) -> mirror (5,0) flips to BACKSLASH (DOWN) -> into fixed mirror (5,2) from the north -> RIGHT -> target B (6,2, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,7) instead. INTENTIONAL DECOY: mirror (2,7) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 7)),
		TilePlacement.make_mirror(Vector2i(2, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(5, 7), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(5, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 2), GridTypes.BeamColor.WHITE),
	]
