extends LevelData
## Campaign Level 1 — "Ignition". Teaches basic mirror rotation: one
## emitter, one mirror, one target. The mirror starts in the wrong
## orientation; a single rotation solves it. See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (1).

func _init() -> void:
	level_id = 1
	display_name = "Ignition"
	stage = "First Light"
	developer_notes = "Teaches: tapping a mirror rotates it. No decoys. Straight single-turn solve by design."
	is_campaign_level = true
	grid_width = 5
	grid_height = 6
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(3, 0)),
	]
