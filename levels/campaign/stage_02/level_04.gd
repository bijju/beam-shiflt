extends LevelData
## Campaign Level 14 (Stage 2 #4) — "Reverse Trace". First dedicated
## backward-reasoning level: a fixed mirror sits directly beside the
## target and only redirects correctly when approached from one specific
## direction, rewarding a player who reasons backward from the target
## rather than forward from the emitter. See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (3).

func _init() -> void:
	level_id = 4
	display_name = "Reverse Trace"
	stage = "Reflection"
	developer_notes = "BACKWARD REASONING: the fixed mirror at (3,0) only sends the beam right into the target when hit traveling UP (SLASH: UP->RIGHT) - any other approach fails. Intended solving order is target -> fixed mirror -> trace the required UP approach back down column 3 -> back to the emitter, not emitter-forward guessing."
	is_campaign_level = true
	grid_width = 5
	grid_height = 6
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_target(Vector2i(4, 0)),
	]
