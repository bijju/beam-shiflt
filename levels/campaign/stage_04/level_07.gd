extends LevelData
## Campaign Level 37 — "Nexus". DIFFICULTY REWORK PASS 2.
## Splitter with two structurally different routes to the same shared
## fixed mirror - the straight branch's route is a portal shortcut, the
## reflected branch's is a plain relay - reaching one shared decision
## point from perpendicular directions.
## See CAMPAIGN_DESIGN.md section 11g (Pass 2).

func _init() -> void:
	level_id = 7
	display_name = "Nexus"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: the straight branch reaches fixed mirror (6,6) via a portal jump, the reflected branch reaches it via a plain 4-mirror relay - two structurally different routes converging on the same shared decision point, arriving from perpendicular directions (straight RIGHT -> DOWN to target A; reflected DOWN -> RIGHT to target B). Straight branch (unconditional RIGHT off splitter (1,3)): mirror (2,3) flips to BACKSLASH (DOWN), mirror (2,5) flips to BACKSLASH (RIGHT), mirror (3,5) flips to BACKSLASH (DOWN), mirror (3,6) flips to BACKSLASH (RIGHT), into portal (4,6)/pair A -> exits (5,6) still moving RIGHT -> into the shared mirror -> DOWN -> target A (6,8, WHITE). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), mirror (2,0) flips to BACKSLASH (DOWN), mirror (2,2) flips to BACKSLASH (RIGHT), mirror (6,2) flips to BACKSLASH (DOWN), into the shared mirror from the north -> RIGHT -> target B (7,6, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,6) instead. INTENTIONAL DECOY: mirror (1,8) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 9
	optimal_moves = 9
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 6)),
		TilePlacement.make_mirror(Vector2i(1, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(4, 6), "A"),
		TilePlacement.make_portal(Vector2i(5, 6), "A"),
		TilePlacement.make_mirror(Vector2i(6, 6), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(6, 8), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 6), GridTypes.BeamColor.WHITE),
	]
