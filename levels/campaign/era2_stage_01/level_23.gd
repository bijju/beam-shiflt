extends LevelData
## Campaign Level 123 — "Prism Relay". One Prism branch activates a
## Receiver directly; a second is recolored through a Filter; a third is
## independent; the Remote Emitter's own beam crosses a Portal before
## reaching its target. No single branch can be ignored - all three
## Prism channels and the Receiver chain are independently required.

func _init() -> void:
	level_id = 23
	display_name = "Prism Relay"
	stage = "Convergence"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel (straight) -> mirror(5,4). Starts SLASH (WRONG - exits top harmlessly); correct BACKSLASH -> DOWN -> column 5 down, clear, to target(5,6) RED - independent. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up, clear, straight into beam_receiver(3,1) - hit directly, powers link 'L123'. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,7). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> filter(5,7) (recolors BLUE -> GREEN) -> target(6,7), which requires GREEN - the post-filter color, not BLUE's own. Separately, remote_emitter(0,9) RIGHT WHITE link 'L123' only fires once GREEN has powered the Receiver -> portal(2,9), pair 'RP123' -> teleports to partner (6,2), direction preserved (RIGHT) -> row 2 to mirror(8,2). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, exits the top boundary instantly); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 8 down, clear, to target(8,4) WHITE. No branch is decorative: RED needs its own mirror, GREEN's receiver-power is mandatory for the remote emitter to ever fire at all, BLUE's filter recolor is mandatory for its own target's color match, and the remote emitter's portal-routed tail has its own independent mirror decision. optimal_moves=3 (mirror(5,4), mirror(3,7), and mirror(8,2) each need one flip)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),

		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 6), GridTypes.BeamColor.RED),

		TilePlacement.make_beam_receiver(Vector2i(3, 1), "L123"),

		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 7), GridTypes.BeamColor.GREEN),
		TilePlacement.make_target(Vector2i(6, 7), GridTypes.BeamColor.GREEN),

		TilePlacement.make_remote_emitter(Vector2i(0, 9), GridTypes.Direction.RIGHT, "L123"),
		TilePlacement.make_portal(Vector2i(2, 9), "RP123"),
		TilePlacement.make_portal(Vector2i(6, 2), "RP123"),
		TilePlacement.make_mirror(Vector2i(8, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 4), GridTypes.BeamColor.WHITE),
	]
