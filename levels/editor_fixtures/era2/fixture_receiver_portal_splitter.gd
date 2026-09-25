extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. A single
## beam hits a SPLITTER; its reflected branch powers Receiver A directly,
## its straight branch transits a PORTAL before reaching Receiver B (a
## DIFFERENT link_id). Each receiver powers its own Remote Emitter, each
## reaching its own required target. Covers "receiver activated through
## splitter branch", "receiver activated through portal", and "two
## receivers" together.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Two Receivers via Splitter/Portal"
	grid_width = 10
	grid_height = 7
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_splitter(Vector2i(3, 3), GridTypes.MirrorOrientation.SLASH, false),

		# Reflected branch (turn via SLASH = UP) -> Receiver A directly.
		TilePlacement.make_beam_receiver(Vector2i(3, 1), "RA"),

		# Straight branch -> PORTAL -> Receiver B.
		TilePlacement.make_portal(Vector2i(5, 3), "RP"),
		TilePlacement.make_portal(Vector2i(8, 3), "RP"),
		TilePlacement.make_beam_receiver(Vector2i(9, 3), "RB"),

		TilePlacement.make_remote_emitter(Vector2i(0, 6), GridTypes.Direction.RIGHT, "RA"),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_target(Vector2i(3, 4)),

		TilePlacement.make_remote_emitter(Vector2i(8, 6), GridTypes.Direction.LEFT, "RB"),
		TilePlacement.make_target(Vector2i(5, 6)),
	]
