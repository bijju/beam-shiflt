extends LevelData
## Campaign Level 27 — "Impasse". DIFFICULTY REWORK PASS 2.
## A single beam threads three filters in sequence (RED -> GREEN -> BLUE) -
## "last filter touched wins" means only the final one determines the
## required target color, and an early wrong turn genuinely lights up a
## non-required decoy of the FIRST filter's color, a false confirmation.
## (A first draft tried to share two filters between a splitter's two
## branches for the order lesson - the solver caught it as UNSOLVABLE
## because the loop-back geometry accidentally ran the beam into its own
## hazard; rebuilt as a single linear path, which cannot self-collide.)
## See CAMPAIGN_DESIGN.md section 11f (Pass 2).

func _init() -> void:
	level_id = 7
	display_name = "Impasse"
	stage = "Split"
	developer_notes = "DESIGN INTENT: one continuous beam passes three filters in order - RED (2,4), GREEN (4,5), BLUE (5,4) - so only the LAST one (BLUE) determines the target's required color, even though the beam was RED and then GREEN earlier in its own journey. Chain: emitter (0,2) RIGHT WHITE -> mirror (2,2) flips to BACKSLASH (DOWN) -> filter (2,4) RED -> mirror (2,5) flips to BACKSLASH (RIGHT) -> mirror (3,5) flips to BACKSLASH (DOWN) -> mirror (3,7) flips to BACKSLASH (RIGHT) -> mirror (4,7) flips to SLASH (UP) -> filter (4,5) GREEN -> mirror (4,4) flips to SLASH (RIGHT) -> filter (5,4) BLUE -> mirror (6,4) flips to SLASH (UP) -> mirror (6,0) flips to BACKSLASH (LEFT) -> target (3,0, BLUE). FALSE CONFIRMATION: if mirror (2,5) is left at its authored SLASH, the beam deflects LEFT into non-required target (1,5, RED) - it lights up in the FIRST filter's color, tempting a player who assumes the first filter is the one that counts, while the real (BLUE) target stays dark. No decoys - every rotatable piece on the true path is load-bearing (solver-confirmed)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 8
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(2, 4), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(1, 5), GridTypes.BeamColor.RED, false),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 7), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(4, 5), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(5, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(6, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(6, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(3, 0), GridTypes.BeamColor.BLUE),
	]
