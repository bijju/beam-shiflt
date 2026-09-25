extends LevelData
## Campaign Level 50 (Stage 5 #10) — "Paradox". STAGE 5 / FILTERS
## FINALE. The hardest level in BeamShift so far. An early mirror gates
## the entire board; two distinct false routes (one becomes the "right"
## color via an unplanned filter crossing but never reaches a target,
## one becomes the objectively correct color then is blocked); a
## splitter whose straight branch must chain through TWO filters in
## sequence (RED -> GREEN -> BLUE, only the LAST recolor survives) while
## the reflected branch must avoid both of those filters entirely,
## passing through its own third filter instead; a fixed mirror gating
## the reflected branch's final approach (light backward reasoning); and
## one confirmed-inert decoy mirror. 7x8 grid. See CAMPAIGN_DESIGN.md
## section 11e.

func _init() -> void:
	level_id = 10
	display_name = "Paradox"
	stage = "Filters"
	developer_notes = "STAGE 5 FINALE. GLOBAL DEPENDENCY: mirror (2,4) authored BACKSLASH gates the entire rest of the board. FALSE ROUTE 1 (hybrid): (2,4) left unrotated sends the beam through fixed mirror (2,6) across row 5, where it incidentally passes through the GREEN filter (5,6) - genuinely becoming GREEN - but continues past without ever reaching a target. FALSE ROUTE 2 (color-valid, blocked): mirror (2,0) authored BACKSLASH sends the beam through the decoy GREEN filter at (1,0) - genuinely the right color for a GREEN-needing target - but blocker (0,0) stops it immediately after. CHAINED RECOLOR (straight branch): splitter (4,0)'s straight branch runs RED through the GREEN filter (6,1), left through mirror (6,2)/(3,2), UP through the BLUE filter (3,1) - only the LAST filter (BLUE) survives to the BLUE target (3,0); the intermediate GREEN never mattered. FILTER AVOIDANCE (reflected branch): the reflected branch runs DOWN through mirror (4,5), through the FIXED mirror (5,5) (always BACKSLASH - its RIGHT-arrival is what sends it DOWN, a light backward-reasoning check), into its own separate GREEN filter (5,6) - the SAME cell False Route 1 crosses, but reached correctly this time - to the GREEN target (5,7). DECOY: mirror (3,4) is never touched by the true solution (solver-confirmed) - it sits centrally, near the false-route-1 crossing, looking relevant. All seven real rotatable pieces - (2,4)/(2,0)/splitter/(6,0)/(6,2)/(3,2)/(4,5) - are load-bearing; only the decoy at (3,4) is not."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(1, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_blocker(Vector2i(0, 0)),
		TilePlacement.make_splitter(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(6, 1), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(6, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(3, 1), GridTypes.BeamColor.BLUE),
		TilePlacement.make_target(Vector2i(3, 0), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(4, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_filter(Vector2i(5, 6), GridTypes.BeamColor.GREEN),
		TilePlacement.make_target(Vector2i(5, 7), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
	]
