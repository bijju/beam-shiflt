extends LevelData
## Campaign Level 110 — "Refraction Nexus". THE FIRST ERA 2 CAMPAIGN
## MILESTONE. All three Era 2 mechanic families (Prism, One-Way Reflector,
## Beam Receiver / Remote Emitter) plus selected Era 1 mechanics (Mirror,
## Portal, Filter, Switch/Gate) in one coherent system, built from a single
## real emitter. Two independent RGB branches off the Prism converge their
## own dependencies onto two spatially separate final targets - one reached
## through a portal+filter detour, the other only reachable once BOTH a
## receiver (powered by a third Prism branch) and a switch (tripped by a
## One-Way-Reflector-gated branch) have independently resolved.

func _init() -> void:
	level_id = 10
	display_name = "Refraction Nexus"
	stage = "Nexus"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4), splitting into three independent branches. RED channel (straight) -> one_way_reflector(6,4), entering RIGHT (always reflective). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, exits the top boundary, the false route: a player who reasons 'this just bends like a mirror, either way is fine' picks the wrong one and silently loses the switch trip downstream); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 6 down to switch(6,6) gate_id 'NX' (trips every pass once correctly routed, does not stop the beam) -> continues off the bottom edge, harmlessly. GREEN channel (reflect(RIGHT,SLASH)=UP) -> column 3 up, clear, into portal(3,0) pair 'NXP' -> teleports to partner (0,8), direction preserved (UP) -> column 0 upward through filter(0,6) (recolors GREEN -> BLUE, continuing) -> passes emitter(0,4)'s own cell harmlessly (emitters are transparent to other beams) -> mirror(0,3). Starts BACKSLASH (WRONG - reflect(UP,BACKSLASH)=LEFT, exits the left edge instantly); correct SLASH -> reflect(UP,SLASH)=RIGHT -> row 3 to target(2,3), which requires BLUE - matching the beam's post-filter color, not its original GREEN. BLUE channel (reflect(RIGHT,BACKSLASH)=DOWN) -> column 3 down, clear, straight into beam_receiver(3,7) - hit directly, no mirror needed - powers link 'NXR' for the next pass, then continues off the bottom edge harmlessly. remote_emitter(5,0) DOWN, color GREEN (deliberately not the default WHITE - see below), link 'NXR' only fires once powered -> column 5 down to gate(5,8) gate_id 'NX', which only opens once the RED channel's switch has independently tripped (a completely separate dependency - receiver-power and switch-trip come from two different Prism branches, so there is no circular wait). Once both have resolved, the beam passes through to mirror(5,9). Starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, exits the left edge); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> to target(7,9), which requires GREEN. The remote emitter's beam color is deliberately set to GREEN specifically so this final target can only be satisfied by completing the full receiver/remote-emitter/switch/gate chain - a WHITE-required target would have let the RED channel alone reach the same cell (via the same reflector+mirror) and falsely solve it without ever using the Receiver at all; this was caught and fixed during design by tracing every beam's color at every cell it could possibly reach, not just its intended path. optimal_moves=3 (one_way_reflector(6,4), mirror(0,3), mirror(5,9) all must be flipped). Two required targets, each needing a genuinely different subset of Era 2's three mechanic families plus Era 1's portal/filter/switch-gate toolkit, full 8x10 board utilization with content spread across the top (portal/mirror/target), middle (emitter/prism/reflector), and bottom (switch/filter/receiver/gate/mirror/targets) thirds of the board."
	is_campaign_level = true
	grid_width = 8
	grid_height = 10
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),

		TilePlacement.make_one_way_reflector(Vector2i(6, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 6), "NX"),

		TilePlacement.make_portal(Vector2i(3, 0), "NXP"),
		TilePlacement.make_portal(Vector2i(0, 8), "NXP"),
		TilePlacement.make_filter(Vector2i(0, 6), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(0, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(2, 3), GridTypes.BeamColor.BLUE),

		TilePlacement.make_beam_receiver(Vector2i(3, 7), "NXR"),
		TilePlacement.make_remote_emitter(Vector2i(5, 0), GridTypes.Direction.DOWN, "NXR", GridTypes.BeamColor.GREEN),
		TilePlacement.make_gate(Vector2i(5, 8), "NX", false),
		TilePlacement.make_mirror(Vector2i(5, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 9), GridTypes.BeamColor.GREEN),
	]
