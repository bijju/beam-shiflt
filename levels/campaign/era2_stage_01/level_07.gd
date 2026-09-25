extends LevelData
## Campaign Level 107 — "Signal Through". The main beam passes through a
## Filter, then a Portal, before ever reaching the Beam Receiver - by the
## time it does, it has crossed to a completely different part of the
## board. The Remote Emitter's own beam then needs one mirror to close
## out a second, spatially disconnected section.

func _init() -> void:
	level_id = 7
	display_name = "Signal Through"
	stage = "Signal"
	developer_notes = "DESIGN INTENT: emitter(0,0) RIGHT WHITE -> filter(2,0) recolors to BLUE (the receiver is color-agnostic so this doesn't gate anything by itself - it's here to establish the Filter-then-Portal chain the brief asked for) -> continues to portal(4,0) pair 'G' -> teleports to partner (1,8), direction preserved (RIGHT) -> row 8 rightward, clear, to beam_receiver(4,8) link 'L107' - reached only via the portal jump, nowhere near the emitter. Powers 'L107' for the next pass. remote_emitter(0,9) RIGHT WHITE link 'L107' fires once powered -> row 9 to mirror(3,9). Starts BACKSLASH (WRONG - reflect(RIGHT,BACKSLASH)=DOWN, and row 9 is the bottom edge, so the beam exits immediately); correct SLASH -> reflect(RIGHT,SLASH)=UP -> column 3 upward, clear, to target(3,6) WHITE. optimal_moves=1 (only the one mirror is rotatable) - the real challenge here is recognizing the beam must cross the portal before the receiver logic even becomes relevant, and that the receiver/remote-emitter pair are the only link between the board's upper-left region and its lower-middle region."
	is_campaign_level = true
	grid_width = 5
	grid_height = 10
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_filter(Vector2i(2, 0), GridTypes.BeamColor.BLUE),
		TilePlacement.make_portal(Vector2i(4, 0), "G"),
		TilePlacement.make_portal(Vector2i(1, 8), "G"),
		TilePlacement.make_beam_receiver(Vector2i(4, 8), "L107"),
		TilePlacement.make_remote_emitter(Vector2i(0, 9), GridTypes.Direction.RIGHT, "L107"),
		TilePlacement.make_mirror(Vector2i(3, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(3, 6), GridTypes.BeamColor.WHITE),
	]
