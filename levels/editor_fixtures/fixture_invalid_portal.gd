extends LevelData
## EDITOR FIXTURE - development/validator testing only, never exposed in
## Level Select (not registered in LevelManager.LEVEL_PATHS). Deliberately
## broken: a single unpaired portal (pair_id shared by only 1 tile, not
## 2). LevelValidator must flag this as an error; LaserSystem must treat
## the portal cell as inert (fail-safe) rather than crashing.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Invalid Portal Pair"
	grid_width = 4
	grid_height = 3
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_portal(Vector2i(1, 1), "LONELY"),
		TilePlacement.make_target(Vector2i(3, 1)),
	]
