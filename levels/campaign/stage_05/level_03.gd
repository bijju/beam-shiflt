extends LevelData
## Campaign Level 43 — "Tangent". DIFFICULTY REWORK PASS 2.
## Splitter where the straight branch's ONLY route to its target crosses
## a mandatory portal (not a shortcut - there is no other way across),
## while the reflected branch is a long independent relay.
## See CAMPAIGN_DESIGN.md section 11h (Pass 2).

func _init() -> void:
	level_id = 3
	display_name = "Tangent"
	stage = "Filters"
	developer_notes = "DESIGN INTENT: the straight branch's target sits on the far side of a gap only the portal bridges - there is no mirror route around it, so the portal is load-bearing, not a shortcut. Straight branch (unconditional RIGHT off splitter (1,3)): mirror (2,3) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (2,2) instead - filter (2,4) sets RED, into portal (2,5)/pair A -> exits (5,6) still moving DOWN -> mirror (5,7) flips to SLASH (LEFT) -> mirror (4,7) flips to BACKSLASH (UP) -> mirror (4,6) flips to BACKSLASH (LEFT) -> target A (3,6, RED). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), mirror (2,0) flips to BACKSLASH (DOWN), mirror (2,1) flips to BACKSLASH (RIGHT), mirror (4,1) flips to BACKSLASH (DOWN), mirror (4,3) flips to BACKSLASH (RIGHT), into target B (6,3, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,5) instead. INTENTIONAL DECOY: mirror (0,7) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 10
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 5)),
		TilePlacement.make_blocker(Vector2i(2, 2)),
		TilePlacement.make_mirror(Vector2i(0, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(2, 4), GridTypes.BeamColor.RED),
		TilePlacement.make_portal(Vector2i(2, 5), "A"),
		TilePlacement.make_portal(Vector2i(5, 6), "A"),
		TilePlacement.make_mirror(Vector2i(5, 7), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(3, 6), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 3), GridTypes.BeamColor.WHITE),
	]
