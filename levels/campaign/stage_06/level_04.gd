extends LevelData
## Campaign Level 54 — "Dual Transit". Post-reboot Levels 51-60.
## Two structurally unrelated portal routes (different pairs, different
## filters) converge on one fixed shared mirror from perpendicular
## directions - the player must independently solve each portal chain's
## color and direction before either target lights. See
## CAMPAIGN_DESIGN.md section 11i.

func _init() -> void:
	level_id = 4
	display_name = "Dual Transit"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: two completely separate portals, each on its own splitter branch, both eventually reach fixed mirror (4,6) from perpendicular directions - the shared mirror's single BACKSLASH orientation happens to serve both (UP->LEFT for the straight branch's delivery, LEFT->UP for the reflected branch's) - the player has to solve two independent portal+filter puzzles and only then notice they converge. Straight branch (unconditional RIGHT off splitter (2,4)): mirror (3,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,3) instead - into portal (3,5)/pair A -> exits (6,8) still moving DOWN -> mirror (6,9) flips to SLASH (LEFT) -> filter (5,9) RED -> mirror (4,9) flips to BACKSLASH (UP) -> into the shared mirror -> LEFT -> mirror (3,6) flips to SLASH (DOWN) -> mirror (3,8) flips to SLASH (LEFT) -> target A (1,8, RED). Reflected branch: splitter flips to SLASH (UP), mirror (2,0) flips to SLASH (RIGHT), into portal (3,0)/pair B -> exits (7,3) still moving RIGHT -> mirror (8,3) flips to SLASH (UP) -> filter (8,1) BLUE -> mirror (8,0) flips to BACKSLASH (LEFT) -> mirror (5,0) flips to SLASH (DOWN) -> mirror (5,6) flips to SLASH (LEFT) -> into the shared mirror from the east -> UP -> target B (4,5, BLUE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,6) instead. INTENTIONAL DECOY: mirror (7,6) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 6)),
		TilePlacement.make_blocker(Vector2i(3, 3)),
		TilePlacement.make_mirror(Vector2i(7, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(3, 5), "A"),
		TilePlacement.make_portal(Vector2i(6, 8), "A"),
		TilePlacement.make_mirror(Vector2i(6, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(5, 9), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(4, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 8), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(1, 8), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_portal(Vector2i(3, 0), "B"),
		TilePlacement.make_portal(Vector2i(7, 3), "B"),
		TilePlacement.make_mirror(Vector2i(8, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(8, 1), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(8, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 5), GridTypes.BeamColor.BLUE),
	]
