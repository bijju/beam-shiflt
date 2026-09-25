extends LevelData
## Campaign Level 30 — "Deadlock". DIFFICULTY REWORK PASS 2, block finale.
## Combines cross-branch dependency (one fixed shared mirror hit by both
## splitter branches from perpendicular directions), a filter on each
## branch, and a blocker-guarded false route - the block's hardest and
## most whole-board puzzle.
## See CAMPAIGN_DESIGN.md section 11f (Pass 2).

func _init() -> void:
	level_id = 10
	display_name = "Deadlock"
	stage = "Split"
	developer_notes = "DESIGN INTENT: fixed mirror (5,5) is hit by both branches from perpendicular directions - straight branch arrives RIGHT (BACKSLASH: RIGHT->DOWN, to target A), reflected branch arrives DOWN after a long loop (BACKSLASH: DOWN->RIGHT, to target B) - one shared fixed orientation serving two independent color-coded deliveries. Straight branch (unconditional RIGHT off splitter (1,4)): filter (2,4) sets RED, mirror (3,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,2) instead, a real punishment for the wrong fork - mirror (3,5) flips to BACKSLASH (RIGHT), into the shared mirror -> DOWN -> target A (5,7, RED). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), filter (2,0) sets BLUE, mirror (4,0) flips to BACKSLASH (DOWN), mirror (4,1) flips to BACKSLASH (RIGHT), mirror (5,1) flips to BACKSLASH (DOWN), into the shared mirror from the north -> RIGHT -> target B (6,5, BLUE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,6) instead. INTENTIONAL DECOY: mirror (3,6) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 6)),
		TilePlacement.make_blocker(Vector2i(3, 2)),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(2, 4), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(5, 7), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(2, 0), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 5), GridTypes.BeamColor.BLUE),
	]
