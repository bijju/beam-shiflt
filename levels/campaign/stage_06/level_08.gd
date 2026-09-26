extends LevelData
## Campaign Level 58 — "Delayed Fault". Post-reboot Levels 51-60.
## Cross-branch dependency (one fixed shared mirror hit from
## perpendicular directions) where the straight branch's mistake isn't
## punished at the very next tile - the beam travels two full cells
## past the wrong turn before the hazard reveals it. See
## CAMPAIGN_DESIGN.md section 11i.

func _init() -> void:
	level_id = 8
	display_name = "Delayed Fault"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: fixed mirror (4,6) is hit by both branches from perpendicular directions - straight arrives DOWN (SLASH: DOWN->LEFT, to target A) and reflected arrives LEFT (SLASH: LEFT->DOWN, to target B). Straight branch (unconditional RIGHT off splitter (1,4)): mirror (2,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam travels two full cells before running into the hazard at (2,2), not the very next tile - mirror (2,5) flips to BACKSLASH (RIGHT), filter (3,5) BLUE, mirror (4,5) flips to BACKSLASH (DOWN), into the shared mirror -> LEFT -> target A (2,6, BLUE). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), mirror (3,0) flips to BACKSLASH (DOWN), mirror (3,1) flips to BACKSLASH (RIGHT), mirror (4,1) flips to BACKSLASH (DOWN), mirror (4,3) flips to BACKSLASH (RIGHT), mirror (5,3) flips to BACKSLASH (DOWN), mirror (5,6) flips to SLASH (LEFT), into the shared mirror from the east -> DOWN -> target B (4,7, WHITE). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into a second, immediate hazard at (1,5) instead - the two branches deliberately use different failure timings for a comparable mistake. (A first draft placed the straight branch's post-mistake dead-end directly adjacent to the reflected branch's own mirrors with no immediate consequence at all, and the solver found a 4-move shortcut where both branches' 'wrong' orientations happened to connect into one continuous path reaching BOTH targets. Rebuilt with a real hazard ending the wrong path and fully disjoint branch zones.) INTENTIONAL DECOY: mirror (6,2) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 5)),
		TilePlacement.make_hazard(Vector2i(2, 2)),
		TilePlacement.make_mirror(Vector2i(6, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(3, 5), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(4, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_target(Vector2i(2, 6), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 7), GridTypes.BeamColor.WHITE),
	]
