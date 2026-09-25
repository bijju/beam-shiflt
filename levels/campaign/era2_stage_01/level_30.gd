extends LevelData
## Campaign Level 130 — "Convergence Matrix". THE SECOND MAJOR ERA 2
## MILESTONE (Levels 121-130's own capstone). GREEN's own path is gated
## TWICE - once by RED's switch, once by the Remote Emitter's switch -
## so GREEN's single target requires FOUR independently-solved pieces to
## have already succeeded (RED's reflector, BLUE's chain powering the
## Receiver, the Remote Emitter's own reflector pass-through, and
## GREEN's own two mirrors) before it can ever complete.

func _init() -> void:
	level_id = 30
	display_name = "Convergence Matrix"
	stage = "Convergence"
	developer_notes = "DESIGN INTENT: emitter(0,5) RIGHT WHITE -> prism(3,5). RED channel (straight) -> one_way_reflector(6,5), entering RIGHT (always reflective). Starts SLASH (WRONG - bends UP, exits top harmlessly); correct BACKSLASH -> bends DOWN -> column 6 down through switch(6,8), gate_id 'CM130A' (doesn't stop the beam) -> mirror(6,9). Starts BACKSLASH (WRONG - reflect(DOWN,BACKSLASH)=RIGHT, sends the beam toward column 8 where the Remote Emitter's own reflector lives - deliberately avoided, see below); correct SLASH -> reflect(DOWN,SLASH)=LEFT -> row 9 leftward, clear, to target(4,9) RED. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to mirror(3,1). Starts SLASH (WRONG - reflect(UP,SLASH)=RIGHT is actually correct here; WRONG is BACKSLASH, reflect(UP,BACKSLASH)=LEFT, harmless miss); correct SLASH -> RIGHT -> row 1 through gate(5,1), gate_id 'CM130A' (needs RED's switch) then immediately gate(6,1), gate_id 'CM130B' (needs the Remote Emitter's own switch, below) - TWO independent gate dependencies back to back. If both open, continue to mirror(7,1). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> column 7 down, clear, to target(7,3) GREEN - GREEN's beam then continues downward (targets never stop a beam) through row 5 (empty at column 7) into BLUE's own mirror(7,7) at row 7, reflecting off it per BLUE's own orientation and exiting harmlessly off the right edge - traced and confirmed this never reaches anything required. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,7). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> row 7 to beam_receiver(5,7) - hit directly, powers link 'CM130R' - then continues to mirror(7,7). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> target(7,8) BLUE. remote_emitter(8,0) DOWN, color GREEN, link 'CM130R' only fires once BLUE has powered the Receiver -> column 8 down, deliberately isolated from every other channel (confirmed: RED's tail was routed LEFT specifically to avoid column 8; GREEN's own stray continuation only ever reaches column 7, not 8) -> switch(8,4), gate_id 'CM130B' (opens GREEN's second gate, doesn't stop this beam) -> continues to one_way_reflector(8,9), entering DOWN. Starts BACKSLASH (WRONG - DOWN is reflective under BACKSLASH, exits the right edge instantly); correct SLASH -> DOWN is pass-through -> continues straight down, unchanged, to target(8,10), which requires GREEN, matching the Remote Emitter's own explicit color. GREEN's own target therefore depends on: RED's reflector+switch (gate A), BLUE's chain powering the Receiver so the Remote Emitter can even fire (gate B's prerequisite), the Remote Emitter's own reflector correctly passing through (gate B's switch), AND GREEN's own two mirrors - a genuine four-way convergence, not a single chain dressed up to look like one. optimal_moves=7 (all seven rotatable tiles must be flipped)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 11
	optimal_moves = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 5)),

		TilePlacement.make_one_way_reflector(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 8), "CM130A"),
		TilePlacement.make_mirror(Vector2i(6, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 9), GridTypes.BeamColor.RED),

		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(5, 1), "CM130A", false),
		TilePlacement.make_gate(Vector2i(6, 1), "CM130B", false),
		TilePlacement.make_mirror(Vector2i(7, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 3), GridTypes.BeamColor.GREEN),

		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(5, 7), "CM130R"),
		TilePlacement.make_mirror(Vector2i(7, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 8), GridTypes.BeamColor.BLUE),

		TilePlacement.make_remote_emitter(Vector2i(8, 0), GridTypes.Direction.DOWN, "CM130R", GridTypes.BeamColor.GREEN),
		TilePlacement.make_switch(Vector2i(8, 4), "CM130B"),
		TilePlacement.make_one_way_reflector(Vector2i(8, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(8, 10), GridTypes.BeamColor.GREEN),
	]
