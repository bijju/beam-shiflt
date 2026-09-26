extends LevelData
## Campaign Level 20 (Stage 2 #10) — "Culmination". Stage 2 finale: a
## seven-segment route (5 rotatable mirrors + 2 fixed) touring most of
## the board, two blockers guarding real wrong forks, one decoy near the
## fixed-mirror cluster, and a backward-reasoning payoff at the target.
## The hardest puzzle in the campaign so far. See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 6x6 -> 6x7 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (5).

func _init() -> void:
	level_id = 10
	display_name = "Culmination"
	stage = "Reflection"
	developer_notes = "STAGE 2 FINALE. BACKWARD REASONING: the two fixed mirrors beside the target (FT2 at (4,1), FT1 at (4,2)) only work when the beam arrives at FT2 traveling RIGHT and at FT1 traveling DOWN - trace backward from the target through both before touching the emitter end. MULTI-STEP DEPENDENCY: the full 7-segment route (M0 through M4, then the two fixed mirrors) means every rotatable mirror's correct orientation only makes sense in light of the whole chain - no piece can be solved in isolation. FALSE ROUTES: M3's wrong orientation sends the beam straight into a blocker at (3,5); M4's wrong orientation sends it into a second blocker at (1,1) - both real, punished wrong forks, not silent exits. INTENTIONAL DECOY: the mirror at (4,4), sitting directly below the fixed-mirror cluster, is never touched by the solved beam (verified against the traced path) but sits exactly where a player scanning the target area would expect something relevant. All 5 rotatable mirrors start wrong."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.DOWN),
		TilePlacement.make_mirror(Vector2i(0, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_blocker(Vector2i(3, 5)),
		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_blocker(Vector2i(1, 1)),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 2)),
	]
