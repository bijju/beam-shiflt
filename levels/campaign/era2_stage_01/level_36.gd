extends LevelData
## Campaign Level 136 — "Portal Relay". Emitter -> Receiver A -> Remote A
## -> Portal -> One-Way Reflector -> Receiver B -> Remote B -> final
## objective. The reflector's WRONG orientation looks like progress (the
## beam keeps moving, bending toward open board) but actually diverts
## away from Receiver B entirely; the correct orientation is to leave it
## unbent (pass-through) so the beam continues straight into the
## receiver below.

func _init() -> void:
	level_id = 36
	display_name = "Portal Relay"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter(0,0) RIGHT WHITE -> mirror(3,0). Starts SLASH (WRONG - exits top instantly); correct BACKSLASH -> DOWN -> beam_receiver(3,2), powers link 'PR136A'. remote_emitter(0,4) RIGHT WHITE link 'PR136A' fires once powered -> mirror(3,4). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> portal(3,6), pair 'PR136P' -> teleports to partner (6,0), direction preserved (DOWN) -> column 6 down to one_way_reflector(6,3), entering DOWN - THE TRAP. Starts BACKSLASH (WRONG - DOWN is reflective under BACKSLASH, bends RIGHT, and the beam keeps travelling, LOOKING like real progress toward open board - but it diverts away from Receiver B, which sits directly below, and never reaches it); correct SLASH -> DOWN is in the {LEFT,DOWN} pass-through pair -> the beam continues straight down, unbent, to beam_receiver(6,5), powers link 'PR136B'. remote_emitter(0,8) RIGHT WHITE link 'PR136B' only fires once Receiver B is powered -> mirror(3,8). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> mirror(3,9). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(5,9) WHITE, the final objective. No circular dependency - each receiver depends only on an earlier, independently-resolved stage. optimal_moves=5 (mirror(3,0), mirror(3,4), one_way_reflector(6,3), mirror(3,8), mirror(3,9) all must be flipped)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 10
	optimal_moves = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 2), "PR136A"),

		TilePlacement.make_remote_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, "PR136A"),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(3, 6), "PR136P"),
		TilePlacement.make_portal(Vector2i(6, 0), "PR136P"),
		TilePlacement.make_one_way_reflector(Vector2i(6, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_beam_receiver(Vector2i(6, 5), "PR136B"),

		TilePlacement.make_remote_emitter(Vector2i(0, 8), GridTypes.Direction.RIGHT, "PR136B"),
		TilePlacement.make_mirror(Vector2i(3, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 9), GridTypes.BeamColor.WHITE),
	]
