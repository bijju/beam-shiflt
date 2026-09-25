extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. A real
## EMITTER powers a BEAM_RECEIVER, which powers a REMOTE_EMITTER (link_id
## "R1"), whose own beam then transits a fixed MIRROR and a FILTER before
## reaching its required target. Covers "single receiver -> remote
## emitter", "-> target", "-> mirror", and "-> filter" in one fixture.
## The remote emitter's beam does not exist at all until
## simulate_until_stable()'s second pass - see ERA_2_DESIGN.md "Beam
## Receiver / Remote Emitter".

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Receiver -> Remote Emitter -> Mirror -> Filter -> Target"
	grid_width = 6
	grid_height = 5
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_beam_receiver(Vector2i(3, 1), "R1"),

		TilePlacement.make_remote_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, "R1"),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_filter(Vector2i(5, 2), GridTypes.BeamColor.RED),
		TilePlacement.make_target(Vector2i(5, 0), GridTypes.BeamColor.RED),
	]
