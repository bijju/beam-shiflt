extends LevelData
## Campaign Level 129 — "Spectral Network". NEAR-FINALE DIFFICULTY. Every
## Era 2 mechanic is load-bearing: a Prism color-order dependency (GREEN
## needs RED's switch), a Receiver/Remote-Emitter chain isolated in its
## own column (the D81 lesson applied from the start), a One-Way
## Reflector whose pass-through behavior is the correct answer, a Portal
## creating a non-local dependency, and filter order matters.

func _init() -> void:
	level_id = 29
	display_name = "Spectral Network"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter(0,5) RIGHT WHITE -> prism(3,5). RED channel (straight) -> one_way_reflector(6,5), entering RIGHT (always reflective). Starts SLASH (WRONG - bends UP, exits top harmlessly); correct BACKSLASH -> bends DOWN -> switch(6,7), gate_id 'SN129' (doesn't stop the beam) -> continues to mirror(6,8). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(8,8) RED, RED's own objective - note the beam exits the grid immediately after (column 9 is out of bounds at width 9), never reaching the Remote Emitter's own column below. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up, clear, into portal(3,0), pair 'SNP129' -> teleports to partner (0,8), direction preserved (UP) -> column 0 upward through filter(0,6) (recolors GREEN -> BLUE, continuing) -> passes emitter(0,5)'s own cell harmlessly (emitters are transparent to other beams) -> mirror(0,3). Starts BACKSLASH (WRONG - reflect(UP,BACKSLASH)=LEFT, exits the left boundary instantly); correct SLASH -> reflect(UP,SLASH)=RIGHT -> row 3 through gate(2,3), gate_id 'SN129' - the SAME gate_id RED's switch opens, a genuine cross-color dependency GREEN cannot bypass. If open, continue to target(5,3), which requires BLUE - the post-filter color. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down, clear, straight into beam_receiver(3,8) - hit directly, no mirror needed, powers link 'SNR129'. Continues (receivers don't stop) to mirror(3,9). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(5,9) BLUE, BLUE's own second objective. remote_emitter(8,0) DOWN, color GREEN, link 'SNR129' only fires once powered -> column 8 down, clear (deliberately isolated from every other channel - the D81 lesson applied from the start of design, not discovered after the fact) -> one_way_reflector(8,9), entering DOWN. Starts BACKSLASH (WRONG - DOWN is reflective under BACKSLASH, bends RIGHT, exits the right edge instantly); correct SLASH -> DOWN is pass-through -> continues straight down, unchanged, to target(8,10), which requires GREEN - matching the remote emitter's own explicit color (not the default WHITE, for the same reason Level 110/120 needed it: a WHITE-required target here would accept RED's own beam too, which reaches this exact column at row 8, one row above). optimal_moves=5 (one_way_reflector(6,5), mirror(6,8), mirror(0,3), mirror(3,9), one_way_reflector(8,9) all must be flipped)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 11
	optimal_moves = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 5)),

		TilePlacement.make_one_way_reflector(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 7), "SN129"),
		TilePlacement.make_mirror(Vector2i(6, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 8), GridTypes.BeamColor.RED),

		TilePlacement.make_portal(Vector2i(3, 0), "SNP129"),
		TilePlacement.make_portal(Vector2i(0, 8), "SNP129"),
		TilePlacement.make_filter(Vector2i(0, 6), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(0, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(2, 3), "SN129", false),
		TilePlacement.make_target(Vector2i(5, 3), GridTypes.BeamColor.BLUE),

		TilePlacement.make_beam_receiver(Vector2i(3, 8), "SNR129"),
		TilePlacement.make_mirror(Vector2i(3, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 9), GridTypes.BeamColor.BLUE),

		TilePlacement.make_remote_emitter(Vector2i(8, 0), GridTypes.Direction.DOWN, "SNR129", GridTypes.BeamColor.GREEN),
		TilePlacement.make_one_way_reflector(Vector2i(8, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(8, 10), GridTypes.BeamColor.GREEN),
	]
