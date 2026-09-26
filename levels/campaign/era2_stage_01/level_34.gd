extends LevelData
## Campaign Level 134 — "Cross Current". Two emitters share ONE One-Way
## Reflector from perpendicular directions (RIGHT/DOWN, both reflective
## under BACKSLASH); Emitter A's tail powers a Receiver, and the Remote
## Emitter it wakes REUSES a second mirror Emitter B's own tail already
## depends on, entering from the opposite side - a genuine network
## reuse, not two independent paths.

func _init() -> void:
	level_id = 34
	display_name = "Cross Current"
	stage = "Advanced"
	developer_notes = "DESIGN INTENT: emitter_A(0,3) RIGHT WHITE -> one_way_reflector(4,3), entering RIGHT (always reflective). emitter_B(4,0) DOWN WHITE -> column 4 down, clear, into the SAME reflector, entering DOWN - the shared resource. Correct = BACKSLASH: A bends DOWN, B (also reflective under BACKSLASH) bends RIGHT. Wrong = SLASH: A bends UP instead (exits top through B's own cell harmlessly); B passes straight through unchanged (SLASH's pass-through pair is {LEFT,DOWN}) and continues down column 4 through beam_receiver(4,6) too - this DOES redundantly power the receiver even with the reflector 'wrong', but B's own target still requires the reflector correct (to turn RIGHT in the first place), so this redundancy never lets the player skip the real decision. Correct path: A bends DOWN -> column 4 down through beam_receiver(4,6) (hit directly, powers link 'CC134') -> continues to mirror(4,7). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(6,7) WHITE, A's own objective. B bends RIGHT at the shared reflector -> row 3 to mirror(7,3) - a SECOND shared resource, this time shared between B and the Remote Emitter below. Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN for B -> column 7 down to mirror(7,4). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(9,4) WHITE, B's own objective. remote_emitter(9,3) LEFT, color GREEN (deliberately not the WHITE default), link 'CC134' only fires once the Receiver is powered -> row 3 leftward into the SAME mirror(7,3), entering LEFT this time - reflect(LEFT,BACKSLASH)=UP, the identical BACKSLASH orientation B's own bend needs, genuinely reusing the network rather than running parallel to it. Bends UP -> column 7 up to mirror(7,2). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> LEFT -> target(5,2), requires GREEN, the Remote Emitter's own objective. The Remote Emitter's explicit GREEN color (not WHITE) is load-bearing, not decorative: leaving mirror(7,3) at its own default SLASH swaps which beam goes which way through it (B ends up heading toward the Remote Emitter's own target, the Remote Emitter's beam ends up heading toward B's own target) - since a first draft gave both beams the default WHITE, this swap satisfied BOTH targets anyway (WHITE matches WHITE regardless of which beam arrived), making mirror(7,3) never need touching at all (solver found a 4-move shortcut). Giving the Remote Emitter its own GREEN breaks the symmetry: the swapped routing now delivers the wrong color to both targets, forcing mirror(7,3) into its one genuinely correct orientation. optimal_moves=5 (the shared reflector, the second shared mirror, and all three tail mirrors must be flipped)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 8
	optimal_moves = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_emitter(Vector2i(4, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_one_way_reflector(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),

		TilePlacement.make_beam_receiver(Vector2i(4, 6), "CC134"),
		TilePlacement.make_mirror(Vector2i(4, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 7), GridTypes.BeamColor.WHITE),

		TilePlacement.make_mirror(Vector2i(7, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(7, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(9, 4), GridTypes.BeamColor.WHITE),

		TilePlacement.make_remote_emitter(Vector2i(9, 3), GridTypes.Direction.LEFT, "CC134", GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(7, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 2), GridTypes.BeamColor.GREEN),
	]
