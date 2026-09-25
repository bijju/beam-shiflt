extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. One WHITE
## beam enters a PRISM; each of its three channels then interacts with a
## different downstream mechanic before reaching its own required target:
## RED -> MIRROR -> target, GREEN -> FILTER (recolored to BLUE) -> target,
## BLUE -> SPLITTER (both branches) -> two targets. Validates "Prism ->
## Filter", "Prism -> Mirror", "Prism -> Splitter", and multi-branch
## simultaneity. All downstream mirrors/splitters are fixed (non-
## rotatable) so this fixture's authored (zero-move) state is itself the
## behavior under test, not a puzzle.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Prism Chain (Mirror/Filter/Splitter)"
	grid_width = 7
	grid_height = 10
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT),
		TilePlacement.make_prism(Vector2i(4, 5)),

		# RED channel (straight) -> MIRROR -> target.
		TilePlacement.make_mirror(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_target(Vector2i(6, 0), GridTypes.BeamColor.RED),

		# GREEN channel (turn via SLASH = UP) -> FILTER (-> BLUE) -> target.
		TilePlacement.make_filter(Vector2i(4, 2), GridTypes.BeamColor.BLUE),
		TilePlacement.make_target(Vector2i(4, 0), GridTypes.BeamColor.BLUE),

		# BLUE channel (turn via BACKSLASH = DOWN) -> SPLITTER -> two targets.
		TilePlacement.make_splitter(Vector2i(4, 7), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_target(Vector2i(4, 9), GridTypes.BeamColor.BLUE), # straight-through branch
		TilePlacement.make_target(Vector2i(0, 7), GridTypes.BeamColor.BLUE), # reflected (LEFT) branch
	]
