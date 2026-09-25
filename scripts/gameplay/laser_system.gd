class_name LaserSystem
extends RefCounted
## Deterministic grid-based multi-beam simulation. This is the single
## source of truth for beam behavior - no physics, no raycasting. See
## ARCHITECTURE.md ("Laser propagation algorithm") for the full write-up
## and DECISIONS.md for why each mechanic behaves the way it does.
##
## Two entry points:
## - simulate() runs exactly ONE pass: every emitter's beam(s), with gate
##   states fixed for the whole pass. Pure function, no autoload/node
##   dependency, fully unit-testable headlessly.
## - simulate_until_stable() re-runs simulate() across multiple passes to
##   resolve switch -> gate dependencies deterministically (see "Switch/
##   gate simulation strategy" in DECISIONS.md). This is what GridManager
##   actually calls.
##
## Per-pass result dictionary shape (returned by simulate()):
## {
##   "beams": Array[{ "segments": Array[Array[Vector2i]], "color": GridTypes.BeamColor }]
##       -- one entry per beam branch (splitters AND prisms create
##          additional branches); "segments" is a list of polylines
##          because a portal transit starts a new segment rather than
##          drawing a line across the teleport distance.
##   "activated_targets": Array[Vector2i]
##   "activated_switch_positions": Array[Vector2i] -- which SWITCH tiles were hit, for visuals
##   "activated_gate_ids": Array[String] -- which gate_id(s) should open as a result
##   "hit_hazard_positions": Array[Vector2i]
##   "hazard_hit": bool
##   "solved": bool -- all REQUIRED targets activated AND no hazard hit
##   "looped": bool -- true if any beam's exploration was cut short by the loop guard
##   "gate_states": Dictionary (gate_id -> bool) -- the states this pass ran with
##   "activated_receiver_positions": Array[Vector2i] -- which BEAM_RECEIVER tiles were hit, for visuals (Era 2)
##   "activated_link_ids": Array[String] -- which receiver link_id(s) became powered as a result (Era 2)
##   "receiver_states": Dictionary (link_id -> bool) -- the states this pass ran with (Era 2)
## }


## Safety backstop only - gate state is monotonic (closed -> open, never
## reverts) within simulate_until_stable(), so convergence is guaranteed
## within at most (gate_count) additional passes after the first. This
## constant exists purely to defend against a future bug reintroducing
## oscillation; it should never actually be the reason a simulation stops.
const MAX_EXTRA_PASSES := 8


static func simulate_until_stable(level_data: LevelData, tile_orientations: Dictionary) -> Dictionary:
	var gate_states: Dictionary = {}
	for t in level_data.tiles:
		if t.tile_type == GridTypes.TileType.GATE:
			gate_states[t.gate_id] = t.initial_open_state

	## Era 2: BEAM_RECEIVER -> REMOTE_EMITTER powering is monotonic
	## (never re-closes) exactly like gate_states, resolved the same way
	## across the same repeated simulate() passes - see ERA_2_DESIGN.md
	## "Beam Receiver / Remote Emitter". Remote emitters always start
	## unpowered/inactive; there is no "initially powered" concept.
	var receiver_states: Dictionary = {}
	for t in level_data.tiles:
		if t.tile_type == GridTypes.TileType.BEAM_RECEIVER:
			receiver_states[t.link_id] = false

	## Fusion Phase 1 (D99): fused colour per node, resolved by the same repeated passes. Each pass
	## the node emits what the PREVIOUS pass's inputs produced, then the new state REPLACES the old
	## one (a node whose inputs vanish falls back to inactive; YELLOW is superseded by WHITE when the
	## third input arrives). Starts from "all inactive" so the result is a pure function of the board.
	var fusion_states: Dictionary = {}
	for t in level_data.tiles:
		if t.tile_type == GridTypes.TileType.FUSION:
			fusion_states[t.position] = -1

	var gate_count := gate_states.size()
	var receiver_count := receiver_states.size()
	var max_passes: int = max(1, gate_count + receiver_count + 1) + MAX_EXTRA_PASSES + fusion_states.size() * 3

	var result: Dictionary = {}
	var converged := false
	var passes := 0
	for _pass_index in range(max_passes):
		passes += 1
		result = simulate(level_data, tile_orientations, gate_states, receiver_states, fusion_states)

		var changed := false
		for opened_gate_id in result["activated_gate_ids"]:
			if not gate_states.get(opened_gate_id, false):
				gate_states[opened_gate_id] = true
				changed = true
		for powered_link_id in result["activated_link_ids"]:
			if not receiver_states.get(powered_link_id, false):
				receiver_states[powered_link_id] = true
				changed = true

		for fpos in fusion_states:
			var new_color: int = result["fusion_colors"].get(fpos, -1)
			if fusion_states[fpos] != new_color:
				fusion_states[fpos] = new_color
				changed = true

		if not changed:
			converged = true
			break

	# Fusion Phase 2: procedural QA asserts a generated board settles BEFORE the pass cap
	# (the cap is only a backstop, never a stopping rule the generator may rely on).
	result["passes"] = passes
	result["converged"] = converged
	return result


## Runs a single pass: every emitter (real and, if its link_id is already
## powered, REMOTE_EMITTER - Era 2) fires, gate states AND receiver_states
## are fixed for the whole pass. Switches/beam receivers hit this pass are
## reported but do NOT affect gate/receiver states within this same pass
## (see DECISIONS.md "Switch/gate simulation strategy" - Era 2's receiver
## dependency reuses the identical strategy).
static func simulate(level_data: LevelData, tile_orientations: Dictionary, gate_states: Dictionary, receiver_states: Dictionary, fusion_states: Dictionary = {}) -> Dictionary:
	var blockers: Dictionary = {}
	var hazards: Dictionary = {}
	var targets: Dictionary = {} # pos -> TilePlacement
	var filters: Dictionary = {} # pos -> BeamColor
	var switches: Dictionary = {} # pos -> gate_id (String)
	var gates: Dictionary = {} # pos -> TilePlacement
	var splitters: Dictionary = {} # pos -> true
	var mirrors: Dictionary = {} # pos -> true
	var portal_positions_by_pair: Dictionary = {} # pair_id -> Array[Vector2i]
	var emitters: Array = []
	var prisms: Dictionary = {} # pos -> true (Era 2)
	var one_way_reflectors: Dictionary = {} # pos -> true (Era 2)
	var beam_receivers: Dictionary = {} # pos -> link_id (String) (Era 2)
	var remote_emitters_by_link: Dictionary = {} # link_id -> Array[TilePlacement] (Era 2)
	var fusions: Dictionary = {} # pos -> TilePlacement (Fusion Phase 1)
	var selectors: Dictionary = {} # pos -> TilePlacement (Splitter Selector, Selector Phase S1)

	for t in level_data.tiles:
		match t.tile_type:
			GridTypes.TileType.BLOCKER:
				blockers[t.position] = true
			GridTypes.TileType.HAZARD:
				hazards[t.position] = true
			GridTypes.TileType.TARGET:
				targets[t.position] = t
			GridTypes.TileType.FILTER:
				filters[t.position] = t.color
			GridTypes.TileType.SWITCH:
				switches[t.position] = t.gate_id
			GridTypes.TileType.GATE:
				gates[t.position] = t
			GridTypes.TileType.SPLITTER:
				splitters[t.position] = true
			GridTypes.TileType.MIRROR:
				mirrors[t.position] = true
			GridTypes.TileType.PORTAL:
				if not portal_positions_by_pair.has(t.pair_id):
					portal_positions_by_pair[t.pair_id] = []
				portal_positions_by_pair[t.pair_id].append(t.position)
			GridTypes.TileType.EMITTER:
				emitters.append(t)
			GridTypes.TileType.PRISM:
				prisms[t.position] = true
			GridTypes.TileType.ONE_WAY_REFLECTOR:
				one_way_reflectors[t.position] = true
			GridTypes.TileType.BEAM_RECEIVER:
				beam_receivers[t.position] = t.link_id
			GridTypes.TileType.REMOTE_EMITTER:
				if not remote_emitters_by_link.has(t.link_id):
					remote_emitters_by_link[t.link_id] = []
				remote_emitters_by_link[t.link_id].append(t)
			GridTypes.TileType.FUSION:
				fusions[t.position] = t
			GridTypes.TileType.SPLITTER_SELECTOR:
				selectors[t.position] = t

	# Only pairs with exactly 2 members are functional. An unpaired/over-
	# paired portal fails safe: the cell is simply inert (treated as an
	# empty cell), never a crash.
	var portal_partner: Dictionary = {} # pos -> other pos
	for pair_id in portal_positions_by_pair:
		var positions: Array = portal_positions_by_pair[pair_id]
		if positions.size() == 2:
			portal_partner[positions[0]] = positions[1]
			portal_partner[positions[1]] = positions[0]

	var beams_out: Array = []
	var activated_targets: Dictionary = {}
	var activated_switch_positions: Dictionary = {}
	var activated_gate_ids: Dictionary = {}
	var hit_hazard_positions: Dictionary = {}
	var looped := false
	var activated_receiver_positions: Dictionary = {} # Era 2
	var activated_link_ids: Dictionary = {} # Era 2
	var selector_hits: Dictionary = {} # pos -> {color -> true}: beams ROUTED this pass (Selector Phase S1)
	var fusion_inputs: Dictionary = {} # pos -> {incoming side (Direction) -> {color -> true}} (Fusion Phase 1)

	# Shared across every beam branch this pass: if any branch reaches a
	# state another branch (or itself) already visited, its future path
	# is fully determined already, so it's safe to stop there. Board state
	# (gate open/closed, mirror/splitter orientation) is fixed for the
	# whole pass, so (position, direction, color) fully determines the
	# rest of a beam's path - no need to also encode board state in the key.
	var visited_states: Dictionary = {}

	# Explicit work list instead of recursion, per architecture rule -
	# splitters push a second branch onto this list rather than calling
	# back into the stepping function.
	var queue: Array = []
	for e in emitters:
		queue.append({
			"position": e.position,
			"direction": e.direction,
			"color": e.color,
			"segments": [[e.position]],
		})
	# Era 2: a REMOTE_EMITTER only fires once its link_id is already
	# powered (from a PRIOR pass's receiver hit - see simulate_until_stable()).
	# Its own beam is otherwise identical to a real EMITTER's.
	for link_id in remote_emitters_by_link:
		if receiver_states.get(link_id, false):
			for re in remote_emitters_by_link[link_id]:
				queue.append({
					"position": re.position,
					"direction": re.direction,
					"color": re.color,
					"segments": [[re.position]],
				})
	# Fusion (Fusion Phase 1, D99): a Fusion Node whose PREVIOUS pass saw a valid input
	# combination (fusion_states[pos] = fused colour) emits ONE beam from its output side.
	# Same fixed-state-per-pass strategy as gates/receivers - see simulate_until_stable().
	for fpos in fusions:
		var fcolor: int = fusion_states.get(fpos, -1)
		if fcolor >= 0:
			queue.append({
				"position": fpos,
				"direction": _fusion_output_dir(fusions[fpos], tile_orientations),
				"color": fcolor,
				"segments": [[fpos]],
			})

	# Hard safety net only. The (position, direction, color) state space is
	# finite for any level, so visited_states pruning already guarantees
	# termination - this just protects against an unforeseen bug rather
	# than being a real limiting factor for any plausible level size.
	const MAX_STEPS := 20000
	var steps := 0

	while queue.size() > 0:
		var beam: Dictionary = queue.pop_back()
		var pos: Vector2i = beam["position"]
		var dir: int = beam["direction"]
		var color: int = beam["color"]
		var segments: Array = beam["segments"]

		var branch_done := false
		while not branch_done:
			steps += 1
			if steps > MAX_STEPS:
				looped = true
				break

			var state_key := "%d,%d|%d|%d" % [pos.x, pos.y, dir, color]
			if visited_states.has(state_key):
				looped = true
				break
			visited_states[state_key] = true

			var next_pos: Vector2i = pos + GridTypes.direction_vector(dir)

			if next_pos.x < 0 or next_pos.y < 0 or next_pos.x >= level_data.grid_width or next_pos.y >= level_data.grid_height:
				segments[-1].append(next_pos)
				break

			pos = next_pos

			if blockers.has(pos):
				segments[-1].append(pos)
				break

			if hazards.has(pos):
				segments[-1].append(pos)
				hit_hazard_positions[pos] = true
				break

			if gates.has(pos):
				var gate_tile: TilePlacement = gates[pos]
				var is_open: bool = gate_states.get(gate_tile.gate_id, gate_tile.initial_open_state)
				if not is_open:
					segments[-1].append(pos)
					break
				continue # open gate: pass through like empty space

			if switches.has(pos):
				activated_switch_positions[pos] = true
				activated_gate_ids[switches[pos]] = true
				continue # switches don't bend or stop the beam

			if beam_receivers.has(pos):
				var receiver_link_id: String = beam_receivers[pos]
				activated_receiver_positions[pos] = true
				if receiver_link_id != "":
					activated_link_ids[receiver_link_id] = true
				continue # receivers don't bend or stop the beam, same as switches (Era 2)

			if fusions.has(pos):
				# A Fusion Node TERMINATES every beam that reaches it: nothing passes straight through
				# (only the fused output, next pass, leaves it). A beam entering through the OUTPUT
				# side is simply absorbed (no input). Only RED/GREEN/BLUE are valid inputs.
				segments[-1].append(pos)
				var entry_side: int = GridTypes.opposite_direction(dir)
				if entry_side != _fusion_output_dir(fusions[pos], tile_orientations) and GridTypes.is_fusion_input_color(color):
					if not fusion_inputs.has(pos):
						fusion_inputs[pos] = {}
					if not fusion_inputs[pos].has(entry_side):
						fusion_inputs[pos][entry_side] = {}
					fusion_inputs[pos][entry_side][color] = true
				break

			if selectors.has(pos):
				# SPLITTER SELECTOR (Selector Phase S1): one beam in, exactly ONE beam out, through the
				# currently selected output side, colour unchanged. A beam entering THROUGH the output
				# side is absorbed (that side is the exit, not an input). Same-pass and stateless: the
				# routing is a pure function of tile_orientations - nothing latches between passes.
				segments[-1].append(pos)
				var selector_out: int = _selector_output_dir(selectors[pos], tile_orientations)
				if GridTypes.opposite_direction(dir) == selector_out:
					break
				if not selector_hits.has(pos):
					selector_hits[pos] = {}
				selector_hits[pos][color] = true
				dir = selector_out
				continue

			if portal_partner.has(pos):
				segments[-1].append(pos) # entry point ends this segment
				pos = portal_partner[pos]
				segments.append([pos]) # exit point starts a new segment (avoids a visual line across the jump)
				continue # direction and color preserved - see DECISIONS.md

			if filters.has(pos):
				color = filters[pos]
				continue # filters don't bend or stop the beam, only recolor it going forward

			if splitters.has(pos):
				segments[-1].append(pos)
				var orientation: int = tile_orientations.get(pos, GridTypes.MirrorOrientation.SLASH)
				var branch_dir: int = GridTypes.reflect(dir, orientation)
				queue.append({
					"position": pos,
					"direction": branch_dir,
					"color": color,
					"segments": [[pos]],
				})
				continue # the beam in THIS loop iteration continues straight, unchanged direction

			if prisms.has(pos):
				segments[-1].append(pos)
				if color == GridTypes.BeamColor.WHITE:
					# WHITE is fully converted - all three channels branch off,
					# nothing continues as WHITE past this point (Era 2).
					for channel in [GridTypes.BeamColor.RED, GridTypes.BeamColor.GREEN, GridTypes.BeamColor.BLUE]:
						queue.append({
							"position": pos,
							"direction": GridTypes.prism_output_direction(dir, channel),
							"color": channel,
							"segments": [[pos]],
						})
					break # this beam branch ends at the prism
				else:
					# A colored beam only ever uses its own matching channel.
					dir = GridTypes.prism_output_direction(dir, color)
					continue

			if mirrors.has(pos):
				segments[-1].append(pos)
				var orientation: int = tile_orientations.get(pos, GridTypes.MirrorOrientation.SLASH)
				dir = GridTypes.reflect(dir, orientation)
				continue

			if one_way_reflectors.has(pos):
				var orientation: int = tile_orientations.get(pos, GridTypes.MirrorOrientation.SLASH)
				if GridTypes.one_way_reflector_is_reflective(dir, orientation):
					segments[-1].append(pos)
					dir = GridTypes.reflect(dir, orientation)
				# else: passes straight through, exactly like an empty cell -
				# no segment point recorded, direction unchanged (Era 2).
				continue

			if targets.has(pos):
				var target_tile: TilePlacement = targets[pos]
				segments[-1].append(pos)
				if GridTypes.target_accepts_color(target_tile.color, color):
					activated_targets[pos] = true
				continue # beam continues past a target so one beam can activate several in sequence

			# empty cell: keep stepping, no segment point recorded

		beams_out.append({"segments": segments, "color": color})

	var required_count := 0
	var required_activated := 0
	for pos in targets:
		if targets[pos].required:
			required_count += 1
			if activated_targets.has(pos):
				required_activated += 1

	# Fusion: derive each node's fused colour from the DISTINCT input colours seen this pass
	# (a set - order, duplicates and same-colour pairs never matter; see GridTypes.combine_beam_colors).
	var fusion_colors: Dictionary = {} # pos -> fused BeamColor (only ACTIVE nodes)
	var fusion_input_masks: Dictionary = {} # pos -> Array of distinct input colours (visual/QA)
	for fpos in fusion_inputs:
		var seen: Dictionary = {}
		for side in fusion_inputs[fpos]:
			for c in fusion_inputs[fpos][side]:
				seen[c] = true
		var seen_colors: Array = seen.keys()
		seen_colors.sort()
		fusion_input_masks[fpos] = seen_colors
		var fused := GridTypes.combine_beam_colors(seen_colors)
		if fused >= 0:
			fusion_colors[fpos] = fused

	var hazard_hit: bool = hit_hazard_positions.size() > 0
	var solved: bool = required_count > 0 and required_activated >= required_count and not hazard_hit

	return {
		"beams": beams_out,
		"activated_targets": activated_targets.keys(),
		"activated_switch_positions": activated_switch_positions.keys(),
		"activated_gate_ids": activated_gate_ids.keys(),
		"hit_hazard_positions": hit_hazard_positions.keys(),
		"hazard_hit": hazard_hit,
		"solved": solved,
		"looped": looped,
		"gate_states": gate_states,
		"activated_receiver_positions": activated_receiver_positions.keys(),
		"activated_link_ids": activated_link_ids.keys(),
		"receiver_states": receiver_states,
		"fusion_colors": fusion_colors,
		"fusion_input_colors": fusion_input_masks,
		"fusion_input_sides": fusion_inputs,
		"fusion_states": fusion_states.duplicate(),
		"selector_hits": selector_hits,
	}


## The live selected OUTPUT direction of a Splitter Selector (Selector Phase S1).
static func _selector_output_dir(tile: TilePlacement, tile_orientations: Dictionary) -> int:
	return int(tile_orientations.get(tile.position, tile.direction))


## The live OUTPUT direction of a Fusion Node: its 4-state orientation from tile_orientations,
## falling back to the authored direction (Fusion Phase 1, D99).
static func _fusion_output_dir(tile: TilePlacement, tile_orientations: Dictionary) -> int:
	return int(tile_orientations.get(tile.position, tile.direction))
