extends LevelData
## Campaign Level 60 — "Threshold of Reason". MAJOR MILESTONE. Post-
## reboot Levels 51-60 finale. Combines a portal-routed straight branch
## (switch, filter, 7-mirror relay) with a 2-filter-order reflected
## branch gated behind that same switch (7-mirror relay) - a genuine
## global dependency plus independent color reasoning on both halves of
## the board. See CAMPAIGN_DESIGN.md section 11i.

func _init() -> void:
	level_id = 10
	display_name = "Threshold of Reason"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: the reflected branch is physically gated at (3,0) until the straight branch's beam crosses a portal AND a switch far downstream - a genuine global dependency, since the reflected branch's own filter-order puzzle (RED then GREEN, last wins) is completely moot until that gate opens. Straight branch (unconditional RIGHT off splitter (1,4)): mirror (2,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (2,2) instead - mirror (2,5) flips to BACKSLASH (RIGHT), mirror (3,5) flips to BACKSLASH (DOWN), mirror (3,6) flips to BACKSLASH (RIGHT), into portal (4,6)/pair A -> exits (6,7) still moving RIGHT -> switch (7,7) [g1] -> mirror (8,7) flips to BACKSLASH (DOWN) -> mirror (8,8) flips to SLASH (LEFT) -> filter (7,8) BLUE -> mirror (6,8) flips to SLASH (DOWN) -> target A (6,9, BLUE). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), filter (2,0) RED, through gate (3,0) [g1, opened by the straight branch's switch], mirror (4,0) flips to BACKSLASH (DOWN), mirror (4,1) flips to BACKSLASH (RIGHT), mirror (5,1) flips to BACKSLASH (DOWN), mirror (5,3) flips to BACKSLASH (RIGHT), filter (6,3) GREEN (overwrites RED), mirror (7,3) flips to SLASH (UP), into target B (7,0, GREEN). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,6) instead. INTENTIONAL DECOY: mirror (8,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 14
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 6)),
		TilePlacement.make_blocker(Vector2i(2, 2)),
		TilePlacement.make_mirror(Vector2i(8, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(4, 6), "A"),
		TilePlacement.make_portal(Vector2i(6, 7), "A"),
		TilePlacement.make_switch(Vector2i(7, 7), "g1"),
		TilePlacement.make_mirror(Vector2i(8, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(8, 8), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(7, 8), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(6, 8), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(6, 9), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(2, 0), GridTypes.BeamColor.RED),
		TilePlacement.make_gate(Vector2i(3, 0), "g1", false),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(6, 3), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(7, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(7, 0), GridTypes.BeamColor.GREEN),
	]
