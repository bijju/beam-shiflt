extends LevelData
## Campaign Level 11 (Stage 2 #1) — "Redirect". Bridge from Stage 1: a
## three-mirror chain, longer than any single Stage 1 fork, easing the
## player into Stage 2's "trace the whole route" mindset without
## resetting to tutorial difficulty. See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (3).

func _init() -> void:
	level_id = 1
	display_name = "Redirect"
	stage = "Reflection"
	developer_notes = "Bridge level: three rotatable mirrors in a chain, all starting wrong. No blocker/decoy - the goal is purely to establish 'trace the full route before rotating' as Stage 2's baseline, one notch past Stage 1's Level 10."
	is_campaign_level = true
	grid_width = 5
	grid_height = 6
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 5)),
	]
