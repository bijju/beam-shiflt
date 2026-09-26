extends LevelData
## Campaign Level 67 — "Chain Reaction". Post-60 Levels 61-70, MASTER
## TIER. Both splitter branches run their own 2-filter-order chain,
## converging on one fixed cross-branch shared mirror - four filters
## total, each branch's final color depending on which one it touched
## LAST. See CAMPAIGN_DESIGN.md section 11j.

func _init() -> void:
	level_id = 7
	display_name = "Chain Reaction"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: fixed mirror (5,6) is hit by both branches from perpendicular directions - straight arrives RIGHT (BACKSLASH: RIGHT->DOWN, to target A) and reflected arrives DOWN (BACKSLASH: DOWN->RIGHT, to target B) - each branch runs its OWN 2-filter order chain (straight: RED then BLUE; reflected: GREEN then... continues past the shared mirror still GREEN, since the shared mirror never recolors), so the two branches' colors must be tracked completely independently despite converging on the same tile. Straight branch (unconditional RIGHT off splitter (2,4)): mirror (3,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,2) instead - mirror (3,6) flips to BACKSLASH (RIGHT), filter (4,6) RED, into the shared mirror -> DOWN -> filter (5,7) BLUE (overwrites RED) -> mirror (5,8) flips to BACKSLASH (RIGHT) -> mirror (6,8) flips to BACKSLASH (DOWN) -> target A (6,9, BLUE). Reflected branch: splitter flips to SLASH (UP), mirror (2,2) flips to BACKSLASH (LEFT), mirror (1,2) flips to BACKSLASH (UP), mirror (1,0) flips to SLASH (RIGHT), filter (3,0) RED, mirror (4,0) flips to BACKSLASH (DOWN), filter (4,1) GREEN (overwrites RED), mirror (4,3) flips to BACKSLASH (RIGHT), mirror (5,3) flips to BACKSLASH (DOWN), into the shared mirror from the north -> RIGHT -> target B (7,6, GREEN). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,7) instead. INTENTIONAL DECOY: mirror (8,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 7)),
		TilePlacement.make_blocker(Vector2i(3, 2)),
		TilePlacement.make_mirror(Vector2i(8, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 6), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_filter(Vector2i(5, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(5, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 9), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(3, 0), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 1), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 6), GridTypes.BeamColor.GREEN),
	]
