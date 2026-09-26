extends LevelData
## Campaign Level 120 — "Era 2 Circuit". THE SECOND MAJOR ERA 2
## MILESTONE. All four Era 2 mechanics (Prism, One-Way Reflector, Beam
## Receiver, Remote Emitter) plus Mirror/Portal/Switch/Gate in one
## system: a shared gate crossing two Prism branches, a genuine
## Receiver->Remote Emitter activation chain, and a final One-Way
## Reflector whose PASS-THROUGH behavior (not a bend) is the correct
## answer.

func _init() -> void:
	level_id = 20
	display_name = "Era 2 Circuit"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter(0,5) RIGHT WHITE -> prism(3,5). RED channel (straight) -> one_way_reflector(6,5), entering RIGHT (always reflective). Starts SLASH (WRONG - bends UP, column 6 up, exits the top boundary - a genuinely plausible-looking alternative, not an obviously bad guess); correct BACKSLASH -> bends DOWN -> column 6 down through switch(6,7), gate_id 'EC120' (doesn't stop the beam) -> mirror(6,8). Starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> to target(7,8) RED. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to mirror(3,0). Starts BACKSLASH (WRONG - reflect(UP,BACKSLASH)=LEFT, harmless miss); correct SLASH -> reflect(UP,SLASH)=RIGHT -> row 0 to mirror(5,0). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, exits top instantly); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 5 down, clear, to gate(5,7), gate_id 'EC120' - the SHARED gate the RED channel's switch opens, a genuine cross-color dependency: GREEN cannot pass here until RED's own one_way_reflector has been correctly set. If open, continue to mirror(5,9). Starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> to target(7,9) GREEN, then continues (targets never stop a beam) to (8,9), which is deliberately EMPTY - see below for why that matters - then exits the grid at the next step. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,10). Starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> row 10 through beam_receiver(7,10) (hit directly, powers link 'EC120R') -> continues to target(8,10), which requires GREEN, not the beam's own BLUE - so BLUE reaching it does NOT accidentally activate it (a WHITE-required target here would have let BLUE bypass the Receiver/Remote Emitter mechanic entirely, since WHITE accepts any color - the same fix Level 110 needed, applied pre-emptively here). remote_emitter(8,0) DOWN, color GREEN, link 'EC120R' only fires once powered -> column 8 down to one_way_reflector(8,4), entering DOWN. Starts BACKSLASH (WRONG - DOWN is reflective under BACKSLASH, bending RIGHT, which immediately exits the grid's right edge here since column 8 is the last column - a dead end); correct SLASH -> DOWN is in the {LEFT,DOWN} pass-through pair -> the beam continues straight DOWN, unchanged, clear through y5-9, landing on target(8,10) - the one tile in this level where the RIGHT answer is to leave the beam's path unbent rather than reflect it. **This reflector was deliberately placed at row 4, not adjacent to GREEN's own final row 9** - a first draft placed it at (8,9), directly in line with where GREEN's beam continues after activating its own target(7,9); regardless of which orientation that reflector was given, GREEN's stray RIGHT-continuation could reach it and (since RIGHT is always reflective) get bent DOWN into target(8,10) too, accidentally satisfying the Receiver/Remote Emitter chain's target with zero use of the Receiver, BLUE, or the remote emitter - caught by the solver reporting a 5-move solution, and then (after a first fix attempt that only changed the reflector's default orientation) a tied 6-move ALTERNATE solution that deliberately mis-set the reflector to re-trigger the exact same GREEN shortcut. Moving the reflector off GREEN's row entirely, so no orientation of it is ever reachable by GREEN's beam at all, is what actually closes this off - not a default-orientation trick. Multiple plausible starting interactions (three independent Prism channels, two Receiver-adjacent mirrors), a genuine remote activation chain, a cross-channel shared gate, and a pass-through-not-reflect finale. optimal_moves=7 (all seven rotatable tiles must be flipped)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 11
	optimal_moves = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 5)),

		TilePlacement.make_one_way_reflector(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 7), "EC120"),
		TilePlacement.make_mirror(Vector2i(6, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 8), GridTypes.BeamColor.RED),

		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(5, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(5, 7), "EC120", false),
		TilePlacement.make_mirror(Vector2i(5, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 9), GridTypes.BeamColor.GREEN),

		TilePlacement.make_mirror(Vector2i(3, 10), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(7, 10), "EC120R"),
		TilePlacement.make_target(Vector2i(8, 10), GridTypes.BeamColor.GREEN),

		TilePlacement.make_remote_emitter(Vector2i(8, 0), GridTypes.Direction.DOWN, "EC120R", GridTypes.BeamColor.GREEN),
		TilePlacement.make_one_way_reflector(Vector2i(8, 4), GridTypes.MirrorOrientation.BACKSLASH),
	]
