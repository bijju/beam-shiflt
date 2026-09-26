extends LevelData
## Campaign Level 8 — "Long Relay". Requires planning a full four-bounce
## route before making any move - all four mirrors start wrong, so a
## player rotating on sight (rather than tracing the whole path first)
## will waste moves. See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x7 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (4).

func _init() -> void:
	level_id = 8
	display_name = "Long Relay"
	stage = "First Light"
	developer_notes = "Teaches: plan the whole 4-bounce route before touching anything. All four mirrors start wrong; no shortcuts or decoys - pure route-planning difficulty."
	is_campaign_level = true
	grid_width = 5
	grid_height = 7
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(1, 6)),
	]
