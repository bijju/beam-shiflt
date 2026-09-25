extends LevelData
## Campaign Level 47 (Stage 5 #7) — BACKWARD FILTER REASONING. Designed
## from both targets backward: each target's required color determines
## which filter must be the LAST one touched, which determines what
## direction the beam must arrive at the shared FIXED mirror (3,3) -
## since that mirror is fixed (not rotatable), the only thing the player
## can actually control is the upstream routing that produces the right
## arrival direction. 6x7 grid. See CAMPAIGN_DESIGN.md section 11e.

func _init() -> void:
	level_id = 7
	display_name = "Transmute"
	stage = "Filters"
	developer_notes = "BACKWARD REASONING: fixed mirror (3,3) (always BACKSLASH) sends a RIGHT-arrival DOWN (toward the GREEN filter/target) and a DOWN-arrival RIGHT (toward the BLUE filter/target) - two completely different outcomes from the SAME fixed piece depending only on approach direction. Working backward from GREEN target (4,6): it needs the beam arriving DOWN at (3,3) is wrong - re-check: GREEN target needs a RIGHT arrival at (3,3) (straight branch, unconditional from the splitter, needs no rotation to arrive there). Working backward from BLUE target (5,4): it needs a DOWN arrival at (3,3), which only happens if the reflected branch is routed up through mirror (2,0) and back down through mirror (3,0) first. FALSE ROUTE: splitter (2,3) authored BACKSLASH sends the reflected branch down into the non-required GREEN decoy at (2,6) instead. Blockers (1,0) and (5,2) cleanly stop mirrors (2,0)/(5,3)'s wrong-orientation exits. FILTER ESSENTIAL: both filters are the only source of color change on their respective branches - removing either fails its target."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_splitter(Vector2i(2, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(2, 6), GridTypes.BeamColor.GREEN, false),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_blocker(Vector2i(1, 0)),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 3), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_filter(Vector2i(3, 4), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 6), GridTypes.BeamColor.GREEN),
		TilePlacement.make_filter(Vector2i(4, 3), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_blocker(Vector2i(5, 2)),
		TilePlacement.make_target(Vector2i(5, 4), GridTypes.BeamColor.BLUE),
	]
