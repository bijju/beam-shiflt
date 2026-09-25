class_name ProceduralComplexity
extends RefCounted
## Practical reasoning-complexity metrics for one procedural puzzle (Difficulty
## System Phase 1, DECISIONS.md D93). Answers "how much thinking does this
## puzzle need?" separately from "how many moves does it need?" - a puzzle of
## 20 obvious independent rotations must score high on moves and near zero on
## dependencies/depth.
##
## Method: ABLATION through the real LaserSystem. Starting from the solved
## configuration, remove one special tile (or revert one required move) and
## ask what the simulator says now. No beam rule is re-implemented here
## (CLAUDE.md rules 1/3/9) and no solver search runs - every metric costs a
## handful of simulate_until_stable() calls, so this is runtime-safe.
##   - A special tile is LOAD-BEARING when removing it from the solved board
##     loses a required target. Mechanics that are merely present on the
##     board score nothing.
##   - A target's CAUSAL SET is the load-bearing tiles whose removal loses it.
##     Dependency depth and mechanic interaction are read off these sets.
##   - A required move is PADDING when reverting it leaves the board solved.
##
## LIMITS (deliberate, "practical not academic"): the intended solution the
## template constructed is used as the move set, so `intended_move_count` is
## an upper bound on the true optimum - pass a LevelSolver result in
## `solver_result` when one exists and `optimal_moves` becomes the verified
## value (a smaller solver value than intended flags a shortcut).

const _SPECIAL_KINDS := {
	GridTypes.TileType.FILTER: "filter",
	GridTypes.TileType.PORTAL: "portal",
	GridTypes.TileType.SWITCH: "switch",
	GridTypes.TileType.BEAM_RECEIVER: "receiver",
	GridTypes.TileType.REMOTE_EMITTER: "remote",
	GridTypes.TileType.PRISM: "prism",
	GridTypes.TileType.SPLITTER: "splitter",
	GridTypes.TileType.ONE_WAY_REFLECTOR: "one_way",
	GridTypes.TileType.FUSION: "fusion",
	GridTypes.TileType.SPLITTER_SELECTOR: "selector",
}

## Tiles a player can rotate. FUSION is 4-state (one tap = one clockwise step); the rest are two-state.
const _ROTATABLE_KINDS := [GridTypes.TileType.MIRROR, GridTypes.TileType.SPLITTER, GridTypes.TileType.ONE_WAY_REFLECTOR, GridTypes.TileType.FUSION, GridTypes.TileType.SPLITTER_SELECTOR]


## One player tap on a rotatable tile: a two-state flip, or a Fusion Node's clockwise quarter-turn.
static func tap_orientation(tile_type: int, current: int) -> int:
	if tile_type == GridTypes.TileType.FUSION or tile_type == GridTypes.TileType.SPLITTER_SELECTOR:
		return (current + 1) % 4
	return GridTypes.MirrorOrientation.BACKSLASH if current == GridTypes.MirrorOrientation.SLASH else GridTypes.MirrorOrientation.SLASH


## Rotatable tile position -> tile_type (mirror/splitter/one-way/fusion) for the greedy/probe searches.
static func rotatable_types(level: LevelData) -> Dictionary:
	var out := {}
	for t in level.tiles:
		if t.rotatable and t.tile_type in _ROTATABLE_KINDS:
			out[t.position] = t.tile_type
	return out


## Returns the metrics dictionary (all keys always present):
##   intended_move_count, required_rotatables, rotatable_count, padding_moves,
##   plain_route_moves, dependent_moves,
##   optimal_moves (solver's if SOLVABLE, else intended), solver_states,
##   shortest_solution_count,
##   meaningful_dependency_count, dependency_depth, mechanic_interaction_count,
##   mechanic_interaction_pairs, mechanic_kinds, distinct_mechanic_kinds,
##   required_branches (beams in the solved state), shared_resource_count,
##   color_dependency_count, gate_switch_dependency_count,
##   portal_dependency_count, receiver_remote_dependency_count,
##   prism_branch_count, one_way_dependency_count, splitter_dependency_count, fusion_dependency_count (D100),
##   prerequisite_chains, convergence_count, independent_route_count,
##   required_target_count, emitter_count, decoy_count, is_single_route,
##   solved (false => the supplied solution does not solve the level).
static func analyze(level: LevelData, solution_orientations: Dictionary, solver_result: Dictionary = {}) -> Dictionary:
	var authored: Dictionary = level.get_initial_tile_orientations()
	var solved_orient: Dictionary = authored.duplicate()
	for pos in solution_orientations:
		solved_orient[pos] = solution_orientations[pos]

	var base: Dictionary = LaserSystem.simulate_until_stable(level, solved_orient)
	var base_targets: Dictionary = _as_set(base["activated_targets"])

	var m := {
		"intended_move_count": 0, "required_rotatables": 0, "rotatable_count": 0,
		"padding_moves": 0, "padding_positions": [], "plain_route_moves": 0, "dependent_moves": 0,
		"optimal_moves": 0, "solver_states": -1, "shortest_solution_count": -1,
		"meaningful_dependency_count": 0, "dependency_depth": 1,
		"mechanic_interaction_count": 0, "mechanic_interaction_pairs": [],
		"mechanic_kinds": [], "distinct_mechanic_kinds": 0,
		"required_branches": base["beams"].size(), "shared_resource_count": 0,
		"color_dependency_count": 0, "gate_switch_dependency_count": 0,
		"portal_dependency_count": 0, "receiver_remote_dependency_count": 0,
		"prism_branch_count": 0, "one_way_dependency_count": 0,
		"splitter_dependency_count": 0, "fusion_dependency_count": 0, "selector_dependency_count": 0, "prerequisite_chains": 0,
		"selector_count": 0, "selector_load_bearing_count": 0, "selector_interaction_count": 0,
		"selector_equivalent_state_count": 0, "selector_downstream_depth": 0, "selector": {},
		"convergence_count": 0, "independent_route_count": 0,
		"required_target_count": 0, "emitter_count": 0, "decoy_count": 0,
		"is_single_route": false, "solved": base["solved"], "load_bearing_units": [],
	}

	for t in level.tiles:
		if t.tile_type == GridTypes.TileType.TARGET and t.required:
			m["required_target_count"] += 1
		elif t.tile_type == GridTypes.TileType.EMITTER or t.tile_type == GridTypes.TileType.REMOTE_EMITTER:
			m["emitter_count"] += 1
		if t.rotatable and t.tile_type in _ROTATABLE_KINDS:
			m["rotatable_count"] += 1

	# --- Required moves: padding vs load-bearing, and which targets each
	# one alone can lose. -------------------------------------------------
	var affected_by_move: Dictionary = {} # pos -> Dictionary(target_pos -> true)
	var four_state := {}
	for t in level.tiles:
		if t.tile_type == GridTypes.TileType.FUSION or t.tile_type == GridTypes.TileType.SPLITTER_SELECTOR:
			four_state[t.position] = true
	for pos in solution_orientations:
		if authored.get(pos, GridTypes.MirrorOrientation.SLASH) == solution_orientations[pos]:
			continue
		# A 4-state tile (Fusion, Splitter Selector) costs its real clockwise tap distance (a Fusion start is always 1).
		m["intended_move_count"] += posmod(int(solution_orientations[pos]) - int(authored[pos]), 4) if four_state.has(pos) else 1
		var reverted: Dictionary = solved_orient.duplicate()
		reverted[pos] = authored[pos]
		var r: Dictionary = LaserSystem.simulate_until_stable(level, reverted)
		if r["solved"]:
			m["padding_moves"] += 1
			m["padding_positions"].append(pos)
			continue
		m["required_rotatables"] += 1
		affected_by_move[pos] = _subtract(base_targets, _as_set(r["activated_targets"]))

	# --- Load-bearing special tiles (ablation). ---------------------------
	var units: Array[Dictionary] = _special_units(level)
	var load_bearing: Array[Dictionary] = []
	for unit in units:
		# A Fusion Node is ablated into a BLOCKER (it still absorbs beams but emits nothing): deleting it would let its
		# input beams run straight on through the empty cell, a counterfactual no player can ever reach (Phase 3, D101).
		var ablated := _without(level, unit["positions"], unit["kind"] == "fusion" or unit["kind"] == "selector")
		var r: Dictionary = LaserSystem.simulate_until_stable(ablated, solved_orient)
		var lost := _subtract(base_targets, _as_set(r["activated_targets"]))
		if not lost.is_empty() or (base["solved"] and not r["solved"]):
			unit["lost"] = lost
			load_bearing.append(unit)

	var gate_ids := {}
	var link_remotes := {}
	for t in level.tiles:
		if t.tile_type == GridTypes.TileType.GATE:
			gate_ids[t.gate_id] = true
		elif t.tile_type == GridTypes.TileType.REMOTE_EMITTER:
			link_remotes[t.link_id] = true

	var kinds_all := {}
	var kinds_per_target: Dictionary = {} # target_pos -> Dictionary(kind -> true)
	var depth_per_target: Dictionary = {}
	for tp in base_targets:
		kinds_per_target[tp] = {}
		depth_per_target[tp] = 1

	# Splitter Selectors (generator V5, D110): a Selector only counts as a mechanic kind / dependency / depth when
	# ProceduralSelectorCheck finds it load-bearing AND not mirror-like (a wrong output meets a mechanic).
	var sel_counted := {}
	if ProceduralSelectorCheck.has_selector(level):
		var sel: Dictionary = ProceduralSelectorCheck.analyze(level, solved_orient, base, load_bearing)
		m["selector"] = sel
		for spos in sel["by_pos"]:
			sel_counted[spos] = sel["by_pos"][spos]["counted"]
		m["selector_count"] = sel["selector_count"]
		m["selector_load_bearing_count"] = sel["load_bearing_count"]
		m["selector_interaction_count"] = sel["interaction_count"]
		m["selector_equivalent_state_count"] = sel["equivalent_state_count"]
		m["selector_downstream_depth"] = sel["max_downstream_depth"]

	for unit in load_bearing:
		if unit["kind"] == "selector" and not sel_counted.get(unit["positions"][0], false):
			continue
		var unit_kinds: Array[String] = [unit["kind"]]
		var nodes := 1
		match unit["kind"]:
			"switch":
				if gate_ids.has(unit["key"]):
					m["gate_switch_dependency_count"] += 1
					unit_kinds.append("gate")
					nodes = 2
			"receiver":
				if link_remotes.has(unit["key"]):
					m["receiver_remote_dependency_count"] += 1
			"portal":
				m["portal_dependency_count"] += 1
			"filter":
				m["color_dependency_count"] += 1
			"prism":
				m["color_dependency_count"] += 1
			"one_way":
				m["one_way_dependency_count"] += 1
			"splitter":
				m["splitter_dependency_count"] += 1
			"fusion":
				m["fusion_dependency_count"] += 1
			"selector":
				m["selector_dependency_count"] += 1
		for k in unit_kinds:
			kinds_all[k] = true
		for tp in unit["lost"]:
			for k in unit_kinds:
				kinds_per_target[tp][k] = true
			depth_per_target[tp] += nodes

	for unit in load_bearing:
		m["load_bearing_units"].append({"kind": unit["kind"], "key": unit["key"], "positions": unit["positions"], "lost": unit["lost"].keys()})
	m["prerequisite_chains"] = m["gate_switch_dependency_count"] + m["receiver_remote_dependency_count"]
	m["mechanic_kinds"] = kinds_all.keys()
	m["distinct_mechanic_kinds"] = kinds_all.size()

	var pairs := {}
	for tp in kinds_per_target:
		var ks: Array = kinds_per_target[tp].keys()
		ks.sort()
		for i in range(ks.size()):
			for j in range(i + 1, ks.size()):
				pairs["%s+%s" % [ks[i], ks[j]]] = true
	m["mechanic_interaction_pairs"] = pairs.keys()
	m["mechanic_interaction_count"] = pairs.size()

	var depth := 1
	for tp in depth_per_target:
		depth = maxi(depth, depth_per_target[tp])
	m["dependency_depth"] = depth

	# Prism branches: solved-state beams that originate AT a prism cell.
	var prism_cells := {}
	for t in level.tiles:
		if t.tile_type == GridTypes.TileType.PRISM:
			prism_cells[t.position] = true
	for beam in base["beams"]:
		var segs: Array = beam["segments"]
		if not segs.is_empty() and not segs[0].is_empty() and prism_cells.has(segs[0][0]):
			m["prism_branch_count"] += 1

	m["shared_resource_count"] = _shared_resource_count(level, base["beams"])

	# --- Route coupling: independent target components. ------------------
	var target_list: Array = base_targets.keys()
	var parent: Dictionary = {}
	for tp in target_list:
		parent[tp] = tp
	for i in range(target_list.size()):
		for j in range(i + 1, target_list.size()):
			if _targets_coupled(target_list[i], target_list[j], affected_by_move, load_bearing):
				_union(parent, target_list[i], target_list[j])
	var roots := {}
	for tp in target_list:
		roots[_find(parent, tp)] = true
	m["independent_route_count"] = roots.size()
	m["convergence_count"] = maxi(target_list.size() - roots.size(), 0)

	# --- Independent-rotation detection. ----------------------------------
	# A required move is "plain" when every target it can lose has an empty
	# causal set: the player just follows that beam and rotates. Those
	# rotations add moves, not reasoning.
	var has_cause := {}
	for unit in load_bearing:
		for tp in unit["lost"]:
			has_cause[tp] = true
	for pos in affected_by_move:
		var lost: Dictionary = affected_by_move[pos]
		var plain := true
		for tp in lost:
			if has_cause.has(tp):
				plain = false
				break
		if plain:
			m["plain_route_moves"] += 1
		else:
			m["dependent_moves"] += 1

	m["meaningful_dependency_count"] = (
		m["gate_switch_dependency_count"] + m["receiver_remote_dependency_count"]
		+ m["portal_dependency_count"] + m["color_dependency_count"]
		+ m["one_way_dependency_count"] + m["splitter_dependency_count"] + m["fusion_dependency_count"] + m["selector_dependency_count"]
		+ m["shared_resource_count"] + m["convergence_count"]
	)

	m["is_single_route"] = (
		m["required_target_count"] == 1 and m["emitter_count"] == 1
		and base["beams"].size() == 1 and load_bearing.is_empty()
	)

	m["decoy_count"] = _decoy_count(level, base["beams"])

	m["optimal_moves"] = m["intended_move_count"]
	if solver_result.get("status", "") == "SOLVABLE":
		m["optimal_moves"] = int(solver_result.get("optimal_moves", m["intended_move_count"]))
		m["solver_states"] = int(solver_result.get("states_explored", -1))
		m["shortest_solution_count"] = int(solver_result.get("shortest_solution_count", -1))
	return m


## Cheap structural read on how self-explanatory the START state is (Phase
## 2A.1). No search, one simulation of the start board:
##   obvious_wrong_required_tiles - required moves whose tile a start-state beam
##       already touches: a player following the beam sees the fault directly.
##   hidden_required_tiles - required moves no start beam touches (typically
##       behind an unpowered Receiver/Gate): nothing on the board points at them.
##   preserved_tiles - solution tiles that already START in their solved
##       orientation (must simply not be disturbed).
##   start_activations - switches + receivers + targets already lit at start
##       (a false sense of completion when > 0).
##   initially_plausible_required_states = hidden + preserved + start_activations:
##       states that do not advertise "this is what to change".
static func start_state_visibility(level: LevelData, solution_orientations: Dictionary) -> Dictionary:
	var authored: Dictionary = level.get_initial_tile_orientations()
	var start: Dictionary = LaserSystem.simulate_until_stable(level, authored)
	var touched := {}
	for beam in start["beams"]:
		touched.merge(_expand_cells(beam))
	var required := 0
	var obvious := 0
	var preserved := 0
	for pos in solution_orientations:
		if authored.get(pos, GridTypes.MirrorOrientation.SLASH) == solution_orientations[pos]:
			preserved += 1
			continue
		required += 1
		if touched.has(pos):
			obvious += 1
	var activations: int = start["activated_switch_positions"].size() + start["activated_receiver_positions"].size() + start["activated_targets"].size()
	var hidden := required - obvious
	return {
		"required_tiles": required,
		"obvious_wrong_required_tiles": obvious,
		"hidden_required_tiles": hidden,
		"preserved_tiles": preserved,
		"start_activations": activations,
		"initially_plausible_required_states": hidden + preserved + activations,
	}


## Proxy for "just rotate whatever the beams touch": a greedy player who only
## considers tiles currently touched by a beam and keeps a flip when it strictly
## raises a visible-progress score (targets >> switches/receivers >> special
## tiles reached >> cells lit). One simulation per candidate flip, at most
## MAX_GREEDY_STEPS steps - not a solver, and not a proof of anything; a
## heuristic read on whether beam-following alone gets through.
const MAX_GREEDY_STEPS := 30

static func greedy_follow_solve(level: LevelData) -> Dictionary:
	var orient: Dictionary = level.get_initial_tile_orientations()
	var rotatable: Dictionary = rotatable_types(level)
	var res: Dictionary = LaserSystem.simulate_until_stable(level, orient)
	var score := _progress_score(level, res)
	var steps := 0
	while steps < MAX_GREEDY_STEPS and not res["solved"]:
		var touched := {}
		for beam in res["beams"]:
			touched.merge(_expand_cells(beam))
		var best_pos = null
		var best_score := score
		for pos in touched:
			if not rotatable.has(pos):
				continue
			var trial: Dictionary = orient.duplicate()
			trial[pos] = tap_orientation(rotatable[pos], orient[pos])
			var s := _progress_score(level, LaserSystem.simulate_until_stable(level, trial))
			if s > best_score:
				best_score = s
				best_pos = pos
		if best_pos == null:
			break
		orient[best_pos] = tap_orientation(rotatable[best_pos], orient[best_pos])
		res = LaserSystem.simulate_until_stable(level, orient)
		score = best_score
		steps += 1
	return {"solved": res["solved"], "steps": steps}


static func _progress_score(level: LevelData, r: Dictionary) -> int:
	var special := {}
	for beam in r["beams"]:
		for c in _expand_cells(beam):
			special[c] = true
	var reached := 0
	for t in level.tiles:
		if t.tile_type in [GridTypes.TileType.FILTER, GridTypes.TileType.PORTAL, GridTypes.TileType.PRISM, GridTypes.TileType.SPLITTER, GridTypes.TileType.ONE_WAY_REFLECTOR, GridTypes.TileType.GATE, GridTypes.TileType.FUSION, GridTypes.TileType.SPLITTER_SELECTOR] and special.has(t.position):
			reached += 1
	return (r["activated_targets"].size() * 100 + (r["activated_switch_positions"].size() + r["activated_receiver_positions"].size()) * 10
		+ reached * 3 + special.size())


# --- Helpers ---------------------------------------------------------------

## One entry per removable "unit": every special tile, with a portal pair
## removed together (removing half a pair is not a meaningful ablation).
## {kind, key (gate_id/link_id/pair_id or ""), positions: Array[Vector2i]}
static func _special_units(level: LevelData) -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	var pairs: Dictionary = {}
	for t in level.tiles:
		if not _SPECIAL_KINDS.has(t.tile_type):
			continue
		var kind: String = _SPECIAL_KINDS[t.tile_type]
		if t.tile_type == GridTypes.TileType.PORTAL:
			if not pairs.has(t.pair_id):
				pairs[t.pair_id] = {"kind": "portal", "key": t.pair_id, "positions": []}
				units.append(pairs[t.pair_id])
			pairs[t.pair_id]["positions"].append(t.position)
			continue
		var key := ""
		if t.tile_type == GridTypes.TileType.SWITCH:
			key = t.gate_id
		elif t.tile_type == GridTypes.TileType.BEAM_RECEIVER or t.tile_type == GridTypes.TileType.REMOTE_EMITTER:
			key = t.link_id
		units.append({"kind": kind, "key": key, "positions": [t.position]})
	return units


static func _without(level: LevelData, positions: Array, as_blocker: bool = false) -> LevelData:
	var copy: LevelData = level.duplicate()
	var kept: Array[TilePlacement] = []
	for t in level.tiles:
		if not positions.has(t.position):
			kept.append(t)
	if as_blocker:
		for p in positions:
			kept.append(TilePlacement.make_blocker(p))
	copy.tiles = kept
	return copy


static func _as_set(items: Array) -> Dictionary:
	var d := {}
	for i in items:
		d[i] = true
	return d


static func _subtract(a: Dictionary, b: Dictionary) -> Dictionary:
	var d := {}
	for k in a:
		if not b.has(k):
			d[k] = true
	return d


static func _find(parent: Dictionary, x):
	while parent[x] != x:
		x = parent[x]
	return x


static func _union(parent: Dictionary, a, b) -> void:
	var ra = _find(parent, a)
	var rb = _find(parent, b)
	if ra != rb:
		parent[ra] = rb


## Two targets are coupled when one required move can lose both, or one
## load-bearing tile is in both causal sets.
static func _targets_coupled(a: Vector2i, b: Vector2i, affected_by_move: Dictionary, load_bearing: Array[Dictionary]) -> bool:
	for pos in affected_by_move:
		var lost: Dictionary = affected_by_move[pos]
		if lost.has(a) and lost.has(b):
			return true
	for unit in load_bearing:
		if unit["lost"].has(a) and unit["lost"].has(b):
			return true
	return false


## Every cell a beam polyline passes through (segments store corner points).
static func _expand_cells(beam: Dictionary) -> Dictionary:
	var cells := {}
	for seg in beam["segments"]:
		for i in range(seg.size()):
			var a: Vector2i = seg[i]
			cells[a] = true
			if i == 0:
				continue
			var prev: Vector2i = seg[i - 1]
			if prev.x != a.x and prev.y != a.y:
				continue
			var step := Vector2i(signi(a.x - prev.x), signi(a.y - prev.y))
			var p := prev
			while p != a and step != Vector2i.ZERO:
				cells[p] = true
				p += step
	return cells


## Rotatable tiles that two or more distinct solved-state beams pass through,
## ignoring each beam's own origin cell (a splitter/prism/portal is the
## origin of the beams it emits - that is branching, not sharing).
static func _shared_resource_count(level: LevelData, beams: Array) -> int:
	var rotatable := {}
	for t in level.tiles:
		if t.rotatable and t.tile_type in [GridTypes.TileType.MIRROR, GridTypes.TileType.ONE_WAY_REFLECTOR]:
			rotatable[t.position] = true
	var hits: Dictionary = {}
	for beam in beams:
		var cells := _expand_cells(beam)
		var segs: Array = beam["segments"]
		if not segs.is_empty() and not segs[0].is_empty():
			cells.erase(segs[0][0])
		for c in cells:
			if rotatable.has(c):
				hits[c] = hits.get(c, 0) + 1
	var shared := 0
	for c in hits:
		if hits[c] >= 2:
			shared += 1
	return shared


## Fixed mirrors/blockers that no solved-state beam touches - inert clutter.
static func _decoy_count(level: LevelData, beams: Array) -> int:
	var visited := {}
	for beam in beams:
		visited.merge(_expand_cells(beam))
	var n := 0
	for t in level.tiles:
		var fixed_mirror: bool = t.tile_type == GridTypes.TileType.MIRROR and not t.rotatable
		if (fixed_mirror or t.tile_type == GridTypes.TileType.BLOCKER) and not visited.has(t.position):
			n += 1
	return n


## Public aliases for the shortcut probe (ProceduralShortcutProbe).
static func touched_cells(beam: Dictionary) -> Dictionary:
	return _expand_cells(beam)


static func progress_score(level: LevelData, r: Dictionary) -> int:
	return _progress_score(level, r)
