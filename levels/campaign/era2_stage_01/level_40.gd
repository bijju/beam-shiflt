extends LevelData
## Campaign Level 140 — "Refraction Engine". THE ERA 2 LEVELS 131-140
## MILESTONE. Four interacting subsystems: RED's own switch opens one of
## GREEN's two gates; BLUE powers a Receiver that starts a genuine
## TWO-STAGE Remote Emitter chain (Remote 1 -> Receiver 2 -> Remote 2),
## where Remote 1's own switch opens GREEN's second gate and Remote 2's
## beam crosses a Portal to reach its own objective; GREEN's single
## target needs both gates plus a Portal-adjacent mirror decision of its
## own, requiring backward reasoning from its required color through
## two independently-resolved subsystems before a single mirror there
## even matters.

func _init() -> void:
	level_id = 40
	display_name = "Refraction Engine"
	stage = "Advanced"
	developer_notes = "DESIGN INTENT: emitter(0,5) RIGHT WHITE -> prism(3,5). RED channel (straight) -> one_way_reflector(6,5), entering RIGHT (always reflective). Starts SLASH (WRONG - bends UP, exits top harmlessly); correct BACKSLASH -> bends DOWN -> switch(6,7), gate_id 'RE140A' (doesn't stop the beam) -> continues to mirror(6,9). Starts BACKSLASH (WRONG - reflect(DOWN,BACKSLASH)=RIGHT, sends the beam toward column 8 where the Remote chain lives - deliberately avoided); correct SLASH -> reflect(DOWN,SLASH)=LEFT -> row 9 leftward, clear, to target(4,9) RED - this requirement is exactly what forces the reflector's WRONG state (which would otherwise risk an accidental switch trip in column 8) out of any valid solution, confirmed by the solver's shortest-solution-count check. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,7). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> beam_receiver(5,7) - hit directly, powers link 'RE140R1' - continues to mirror(7,7). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> target(7,8) BLUE, BLUE's own objective. remote_emitter 1(8,0) DOWN, color GREEN, link 'RE140R1' only fires once BLUE has powered the Receiver -> column 8 down, isolated from every other channel -> switch(8,4), gate_id 'RE140B' (opens GREEN's second gate, doesn't stop this beam) -> continues to one_way_reflector(8,9), entering DOWN. Starts BACKSLASH (WRONG - reflective, bends RIGHT, exits right edge instantly); correct SLASH -> pass-through -> continues straight down to beam_receiver(8,10) - STAGE TWO - hit directly, powers link 'RE140R2'. remote_emitter 2(1,10) UP, color BLUE, link 'RE140R2' only fires once Remote 1's own chain has powered Receiver 2 - a genuine two-stage remote activation - -> column 1 up to mirror(1,1). Starts BACKSLASH (WRONG - reflect(UP,BACKSLASH)=LEFT, exits left instantly); correct SLASH -> RIGHT -> portal(2,1), pair 'RE140P' -> teleports to partner (6,2), direction preserved (RIGHT) -> row 2 rightward, clear, to target(8,2) BLUE, Remote 2's own objective. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to mirror(3,1). Starts BACKSLASH (WRONG - harmless miss); correct SLASH -> RIGHT -> row 1 through gate(5,1), gate_id 'RE140A' (needs RED's switch) then gate(6,1), gate_id 'RE140B' (needs Remote 1's switch, itself gated behind BLUE's own chain) - TWO independently-resolved subsystems in sequence. If both open, continue to mirror(7,1). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> target(7,3) GREEN, the final objective - reachable only once RED's reflector, BLUE's two mirrors plus Receiver, Remote 1's own reflector pass-through, and GREEN's own two mirrors have ALL independently resolved. optimal_moves=8 (all eight rotatable tiles must be flipped)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 11
	optimal_moves = 8
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 5)),

		TilePlacement.make_one_way_reflector(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 7), "RE140A"),
		TilePlacement.make_mirror(Vector2i(6, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 9), GridTypes.BeamColor.RED),

		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(5, 7), "RE140R1"),
		TilePlacement.make_mirror(Vector2i(7, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 8), GridTypes.BeamColor.BLUE),

		TilePlacement.make_remote_emitter(Vector2i(8, 0), GridTypes.Direction.DOWN, "RE140R1", GridTypes.BeamColor.GREEN),
		TilePlacement.make_switch(Vector2i(8, 4), "RE140B"),
		TilePlacement.make_one_way_reflector(Vector2i(8, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_beam_receiver(Vector2i(8, 10), "RE140R2"),

		TilePlacement.make_remote_emitter(Vector2i(1, 10), GridTypes.Direction.UP, "RE140R2", GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(1, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_portal(Vector2i(2, 1), "RE140P"),
		TilePlacement.make_portal(Vector2i(6, 2), "RE140P"),
		TilePlacement.make_target(Vector2i(8, 2), GridTypes.BeamColor.BLUE),

		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(5, 1), "RE140A", false),
		TilePlacement.make_gate(Vector2i(6, 1), "RE140B", false),
		TilePlacement.make_mirror(Vector2i(7, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 3), GridTypes.BeamColor.GREEN),
	]
