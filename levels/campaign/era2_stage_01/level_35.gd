extends LevelData
## Campaign Level 135 — "Delayed Spectrum". MAJOR MID-BLOCK CHECKPOINT.
## The RED channel's beam activates its own required target, then keeps
## traveling (targets never stop a beam) into a Beam Receiver that
## wakes a Remote Emitter elsewhere - fair and visually traceable, since
## the continuation is a straight, unbroken line the player can follow
## with their eyes from the target onward.

func _init() -> void:
	level_id = 35
	display_name = "Delayed Spectrum"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel (straight) -> target(6,4), requires RED, activates - then CONTINUES in the same straight line (targets never stop a beam) to beam_receiver(8,4), hit directly, powering link 'DS135'. A player who sees the RED target light up and stops reasoning here misses that the same beam's onward path is the actual key to the rest of the level - the continuation is a plain straight line along row 4, fully visible, not hidden. remote_emitter(0,7) RIGHT, color GREEN, link 'DS135' only fires once powered -> mirror(5,7). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> target(5,8), requires GREEN, matching the Remote Emitter's own explicit color. GREEN channel (the Prism's own, unrelated to the Remote Emitter sharing its color by coincidence) = reflect(RIGHT,SLASH)=UP -> column 3 up to mirror(3,1). Starts BACKSLASH (WRONG - reflect(UP,BACKSLASH)=LEFT, exits the left boundary instantly); correct SLASH -> reflect(UP,SLASH)=RIGHT -> target(6,1) GREEN - independent. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,8). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> row 8 through target(5,8) (BLUE passing through - color mismatch, GREEN required, harmless) -> target(6,8) BLUE - independent. optimal_moves=3 (mirror(3,1), mirror(3,8), mirror(5,7) all must be flipped) - deliberately modest; the checkpoint's real difficulty is recognizing the continuation matters at all, not move count."
	is_campaign_level = true
	grid_width = 9
	grid_height = 9
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),
		TilePlacement.make_target(Vector2i(6, 4), GridTypes.BeamColor.RED),
		TilePlacement.make_beam_receiver(Vector2i(8, 4), "DS135"),

		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(6, 1), GridTypes.BeamColor.GREEN),

		TilePlacement.make_mirror(Vector2i(3, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 8), GridTypes.BeamColor.BLUE),

		TilePlacement.make_remote_emitter(Vector2i(0, 7), GridTypes.Direction.RIGHT, "DS135", GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(5, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 8), GridTypes.BeamColor.GREEN),
	]
