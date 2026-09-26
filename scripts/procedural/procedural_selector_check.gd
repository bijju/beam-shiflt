class_name ProceduralSelectorCheck
extends RefCounted
## First-class Splitter Selector analysis for GENERATED boards (Selector Phase S3 / generator V5, D110).
## Runtime-safe like ProceduralComplexity/ProceduralFusionCheck: only the real LaserSystem is ever asked
## anything (CLAUDE.md rules 1/3/9) - never LevelSolver/LevelValidator, never a second beam model.
##
## A Selector is meaningful only when changing its selected output changes an important downstream
## requirement. For every Selector on the SOLVED board this class runs (5 simulations each):
##   A. removal        - the tile deleted (empty cell): the puzzle must not stay solved (a "straight
##                       through" bypass would be reachable by the player as the straight orientation);
##   B. blocker        - the tile replaced by a blocker (the load-bearing test, D101 style): at least one
##                       required target must be lost - otherwise the Selector is decorative;
##   C. every OTHER orientation (three states) with everything else solved: none may solve the puzzle
##                       (that would be a shortcut / a functionally equivalent state);
##   D. equivalence    - distinct outcome signatures among the four states (targets/switches/receivers/
##                       gates/fusions lit + the cells touched); states that behave identically are not
##                       counted as separate choices.
## A wrong state is CONSEQUENTIAL when it differs from the dead (blocker) state - it lights, opens or
## recolours something, or meets a non-mirror mechanic the dead state never reaches. A Selector whose wrong
## states are all inert behaves like a plain mirror: it is reported "mirror_like" and does NOT count as a
## mechanic kind, a dependency or depth (ProceduralComplexity.analyze reads `counted`), and generation
## rejects it. Selector metrics exposed to QA: selector_count, selector_load_bearing_count,
## selector_dependency_count, selector_interaction_count, selector_equivalent_state_count,
## selector_downstream_depth (see analyze()'s return value).

const _DIRS := [GridTypes.Direction.UP, GridTypes.Direction.RIGHT, GridTypes.Direction.DOWN, GridTypes.Direction.LEFT]
## Tiles that are NOT mechanics: a wrong beam meeting only these is not a consequence.
const _PLAIN_TYPES := [GridTypes.TileType.MIRROR, GridTypes.TileType.BLOCKER, GridTypes.TileType.EMITTER, GridTypes.TileType.EMPTY]


static func has_selector(level: LevelData) -> bool:
	for t in level.tiles:
		if t.tile_type == GridTypes.TileType.SPLITTER_SELECTOR:
			return true
	return false


## `solved`: full orientation map of the solved state; `base`: its simulation; `units`: the load-bearing
## special units ProceduralComplexity found (for the downstream-depth read).
## Returns {selectors: Array[Dictionary], by_pos: Dictionary, reasons: Array[String], selector_count,
## load_bearing_count, counted_count, dependency_count, interaction_count, equivalent_state_count,
## max_downstream_depth, consequential_count, coupled_pairs, converging, live_wrong_states, sims}.
static func analyze(level: LevelData, solved: Dictionary, base: Dictionary, units: Array) -> Dictionary:
	var lost_sets: Dictionary = {} # selector pos -> targets lost when it is dead (shared-target convergence)
	var out := {
		"selectors": [], "by_pos": {}, "reasons": [], "selector_count": 0, "load_bearing_count": 0, "counted_count": 0,
		"dependency_count": 0, "interaction_count": 0, "equivalent_state_count": 0, "max_downstream_depth": 0,
		"consequential_count": 0, "max_distinct_wrong": 0, "coupled_pairs": 0, "converging": false, "live_wrong_states": 0, "sims": 0,
	}
	var tiles: Array[TilePlacement] = []
	for t in level.tiles:
		if t.tile_type == GridTypes.TileType.SPLITTER_SELECTOR:
			tiles.append(t)
	if tiles.is_empty():
		return out
	var occupied := {}
	var type_at := {}
	for t in level.tiles:
		occupied[t.position] = true
		type_at[t.position] = t.tile_type
	var base_targets: Dictionary = _as_set(base["activated_targets"])
	var wrong_results: Dictionary = {} # selector pos -> Array of {o, res}
	var downstream: Dictionary = {} # selector pos -> cells

	for s in tiles:
		var pos: Vector2i = s.position
		var info := {
			"pos": pos, "solved_dir": int(solved[pos]), "load_bearing": false, "removal_solves": false,
			"wrong": [], "consequential": 0, "solving_wrong": 0, "equivalent_states": 0, "live_outputs": 0,
			"mirror_like": true, "downstream_depth": 0, "arrival_sides": [], "counted": false, "reasons": [],
		}
		var sides := {}
		for a in ProceduralFusionCheck._arrivals(base, pos):
			sides[int(String(a).split("|")[0])] = true
		info["arrival_sides"] = sides.keys()

		# B. blocker ablation (load-bearing) - the dead state every wrong output is compared against.
		var dead: Dictionary = LaserSystem.simulate_until_stable(_swap(level, pos, TilePlacement.make_blocker(pos)), solved)
		out["sims"] += 1
		var lost := _subtract(base_targets, _as_set(dead["activated_targets"]))
		info["load_bearing"] = not lost.is_empty() or (base["solved"] and not dead["solved"])
		lost_sets[pos] = lost
		var dead_act := _activation_sig(dead)
		var dead_special := _special_cells(level, dead, pos, type_at)
		# A. removal.
		var removed: Dictionary = LaserSystem.simulate_until_stable(_swap(level, pos, null), solved)
		out["sims"] += 1
		info["removal_solves"] = bool(removed["solved"])

		# C/D. the three other orientations.
		var sigs := {_full_sig(base): true}
		var wrong_sigs := {}
		var wrongs: Array = []
		for o in _DIRS:
			if o == int(solved[pos]):
				continue
			var trial: Dictionary = solved.duplicate()
			trial[pos] = o
			var res: Dictionary = LaserSystem.simulate_until_stable(level, trial)
			out["sims"] += 1
			var solves: bool = res["solved"]
			var absorbed: bool = sides.has(o)
			var special := _special_cells(level, res, pos, type_at)
			var conseq := (not absorbed) and (_activation_sig(res) != dead_act or _has_new(special, dead_special))
			var sig := _full_sig(res)
			if sigs.has(sig):
				info["equivalent_states"] += 1
			sigs[sig] = true
			if not absorbed:
				wrong_sigs[sig] = true
			if solves:
				info["solving_wrong"] += 1
			if conseq:
				info["consequential"] += 1
			info["wrong"].append({"o": o, "solves": solves, "absorbed": absorbed, "consequential": conseq})
			wrongs.append({"o": o, "res": res})
		wrong_results[pos] = wrongs
		info["distinct_wrong"] = wrong_sigs.size()
		# Live wrong rays: wrong outputs whose ray travels >= 2 cells or meets a non-blocker tile before it ends.
		var live_rays := 0
		for w in info["wrong"]:
			if bool(w["absorbed"]):
				continue
			if _ray_is_live(level, pos, int(w["o"]), type_at):
				live_rays += 1
		info["live_wrong_rays"] = live_rays
		# mirror-like = a plain two-state turn in disguise: no wrong output changes a state or meets a mechanic AND fewer
		# than two wrong rays are even live (a three-way decision among plausible routes is not mirror-like). The strict
		# bands additionally demand, per LEVEL, one Selector with a genuinely consequential wrong state (reasons_for).
		info["mirror_like"] = int(info["consequential"]) == 0 and live_rays < 2
		# Geometry: outputs whose adjacent cell is inside the board and not a blocker.
		var live := 0
		for d in _DIRS:
			if sides.has(d):
				continue
			var nb: Vector2i = pos + GridTypes.direction_vector(d)
			if nb.x < 0 or nb.y < 0 or nb.x >= level.grid_width or nb.y >= level.grid_height:
				continue
			if type_at.get(nb, -1) == GridTypes.TileType.BLOCKER:
				continue
			live += 1
		info["live_outputs"] = live

		downstream[pos] = _downstream_cells(level, base, pos)
		var depth := 0
		var kinds := {}
		for u in units:
			if u["kind"] == "selector":
				continue
			for p in u["positions"]:
				if downstream[pos].has(p):
					depth += 1
					kinds[u["kind"]] = true
					break
		info["downstream_depth"] = depth
		info["downstream_kinds"] = kinds.keys()

		# Reasons (each names the triviality rule it enforces).
		if not info["load_bearing"]:
			info["reasons"].append("selector at %s is not load-bearing (a blocker in its place loses no target)" % pos)
		if info["removal_solves"]:
			info["reasons"].append("selector at %s can be removed and the puzzle stays solved" % pos)
		if int(info["solving_wrong"]) > 0:
			info["reasons"].append("selector at %s has %d other orientation(s) that also solve (shortcut / equivalent state)" % [pos, info["solving_wrong"]])
		if live < 2:
			info["reasons"].append("selector at %s has only %d live output(s) (its correct output is obvious)" % [pos, live])
		if bool(info["mirror_like"]):
			info["reasons"].append("selector at %s is mirror-like (no wrong output meets a mechanic or changes a state; %d live wrong ray(s))" % [pos, live_rays])
		info["counted"] = bool(info["load_bearing"]) and not bool(info["mirror_like"]) and int(info["solving_wrong"]) == 0
		out["selectors"].append(info)
		out["by_pos"][pos] = info
		out["selector_count"] += 1
		if info["load_bearing"]:
			out["load_bearing_count"] += 1
		if info["counted"]:
			out["counted_count"] += 1
		out["consequential_count"] += int(info["consequential"])
		out["equivalent_state_count"] += int(info["equivalent_states"])
		out["live_wrong_states"] += int(info["consequential"])
		out["max_downstream_depth"] = maxi(int(out["max_downstream_depth"]), depth)
		out["max_distinct_wrong"] = maxi(int(out["max_distinct_wrong"]), int(info["distinct_wrong"]))
		out["interaction_count"] += kinds.size()

	# Coupling between Selectors: a wrong state of i changes what reaches j (j is downstream of i), or two
	# Selectors feed a common tile (their downstream cells intersect).
	if tiles.size() >= 2:
		var base_arrivals := {}
		for s in tiles:
			base_arrivals[s.position] = ProceduralFusionCheck._arrivals(base, s.position)
		var pairs := 0
		for si in tiles:
			for sj in tiles:
				if si == sj:
					continue
				for w in wrong_results[si.position]:
					if ProceduralFusionCheck._arrivals(w["res"], sj.position) != base_arrivals[sj.position]:
						pairs += 1
						break
		out["coupled_pairs"] = pairs
		for a in range(tiles.size()):
			for b in range(a + 1, tiles.size()):
				for c in downstream[tiles[a].position]:
					if downstream[tiles[b].position].has(c):
						out["converging"] = true
						break
				# Two Selectors that are both REQUIRED for the same target are jointly load-bearing: converging on it.
				for tgt in lost_sets[tiles[a].position]:
					if lost_sets[tiles[b].position].has(tgt):
						out["converging"] = true
						break
	out["dependency_count"] = out["counted_count"]
	return out


## Reasons a generated board must be rejected for its Selectors (empty = fine). Also enforces the
## multi-Selector rule (independent one-step decisions) and the band's downstream-reasoning floor.
static func reasons_for(sel: Dictionary, min_downstream_depth: int, strict: bool = false) -> Array[String]:
	var reasons: Array[String] = []
	for info in sel["selectors"]:
		for r in info["reasons"]:
			reasons.append(r)
	if int(sel["selector_count"]) >= 2 and int(sel["coupled_pairs"]) == 0 and not bool(sel["converging"]):
		reasons.append("%d selectors are independent one-step decisions (no coupling, no shared downstream)" % sel["selector_count"])
	if strict and int(sel["selector_count"]) > 0 and int(sel["consequential_count"]) == 0:
		reasons.append("no selector has a wrong output that changes a state or meets a mechanic (strict band)")
	if strict and int(sel["selector_count"]) > 0 and int(sel["max_distinct_wrong"]) < 2:
		reasons.append("no selector is a genuine multi-way decision (fewer than 2 distinct live wrong outcomes; strict band)")
	if int(sel["selector_count"]) > 0 and int(sel["max_downstream_depth"]) < min_downstream_depth:
		reasons.append("selector reasoning stays adjacent: max downstream depth %d < %d" % [sel["max_downstream_depth"], min_downstream_depth])
	return reasons


# --- helpers ---------------------------------------------------------------------------------

## A wrong output ray is LIVE when its first cell is free and it either runs >= 2 cells or meets a non-blocker tile.
static func _ray_is_live(level: LevelData, spos: Vector2i, dir: int, type_at: Dictionary) -> bool:
	var step: Vector2i = GridTypes.direction_vector(dir)
	var p: Vector2i = spos + step
	var travelled := 0
	while p.x >= 0 and p.y >= 0 and p.x < level.grid_width and p.y < level.grid_height:
		if type_at.has(p):
			return type_at[p] != GridTypes.TileType.BLOCKER
		travelled += 1
		if travelled >= 2:
			return true
		p += step
	return false


## The level with the tile at `pos` replaced by `replacement` (or removed when null).
static func _swap(level: LevelData, pos: Vector2i, replacement: TilePlacement) -> LevelData:
	var copy: LevelData = level.duplicate()
	var kept: Array[TilePlacement] = []
	for t in level.tiles:
		if t.position != pos:
			kept.append(t)
	if replacement != null:
		kept.append(replacement)
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


## Everything a state "does": targets/switches/receivers lit, gates open, fusion colours produced.
static func _activation_sig(res: Dictionary) -> String:
	var parts: Array = []
	for key in ["activated_targets", "activated_switch_positions", "activated_receiver_positions", "activated_gate_ids"]:
		var arr: Array = res[key].duplicate()
		arr.sort()
		parts.append(str(arr))
	var fk: Array = res["fusion_colors"].keys()
	fk.sort()
	var fs := []
	for k in fk:
		fs.append("%s:%d" % [k, res["fusion_colors"][k]])
	parts.append(str(fs))
	return "|".join(parts)


static func _all_cells(res: Dictionary) -> Dictionary:
	var cells := {}
	for beam in res["beams"]:
		cells.merge(ProceduralComplexity.touched_cells(beam))
	return cells


static func _full_sig(res: Dictionary) -> String:
	var cells: Array = _all_cells(res).keys()
	cells.sort()
	return "%s#%s" % [_activation_sig(res), str(cells).md5_text()]


## Mechanic tiles (anything that is not a plain mirror/blocker/emitter) a state's beams touch, excluding the
## Selector itself.
static func _special_cells(level: LevelData, res: Dictionary, selector_pos: Vector2i, type_at: Dictionary) -> Dictionary:
	var cells := _all_cells(res)
	var out := {}
	for c in cells:
		if c == selector_pos or not type_at.has(c):
			continue
		if not _PLAIN_TYPES.has(type_at[c]):
			out[c] = true
	return out


static func _has_new(a: Dictionary, b: Dictionary) -> bool:
	for k in a:
		if not b.has(k):
			return true
	return false


## Ordered cell path of one beam (segments store corner points; portal jumps continue into the next segment).
static func _ordered_cells(beam: Dictionary) -> Array:
	var out: Array = []
	for seg in beam["segments"]:
		for i in range(seg.size()):
			var a: Vector2i = seg[i]
			if i == 0:
				out.append(a)
				continue
			var prev: Vector2i = seg[i - 1]
			if prev.x != a.x and prev.y != a.y:
				out.append(a)
				continue
			var step := Vector2i(signi(a.x - prev.x), signi(a.y - prev.y))
			var p := prev + step
			while step != Vector2i.ZERO:
				out.append(p)
				if p == a:
					break
				p += step
	return out


## Cells that the solved board's beams reach AFTER the Selector: the rest of the beam through it, then every
## beam that starts on such a cell (splitter/prism/fusion output), and every Remote Emitter whose Receiver
## sits on such a cell (a hop starts a new route). Fixed point over those rules.
static func _downstream_cells(level: LevelData, base: Dictionary, spos: Vector2i) -> Dictionary:
	var cells := {}
	var beams: Array = base["beams"]
	var paths: Array = []
	for beam in beams:
		paths.append(_ordered_cells(beam))
	var receiver_link := {}
	var remote_links := {}
	for t in level.tiles:
		if t.tile_type == GridTypes.TileType.BEAM_RECEIVER:
			receiver_link[t.position] = t.link_id
		elif t.tile_type == GridTypes.TileType.REMOTE_EMITTER:
			remote_links[t.position] = t.link_id
	var used := {}
	for bi in range(paths.size()):
		var idx: int = paths[bi].find(spos)
		if idx >= 0:
			used[bi] = true
			for k in range(idx + 1, paths[bi].size()):
				cells[paths[bi][k]] = true
	var grew := true
	while grew:
		grew = false
		for bi in range(paths.size()):
			if used.has(bi) or paths[bi].is_empty():
				continue
			var first: Vector2i = paths[bi][0]
			var starts_downstream: bool = cells.has(first)
			if not starts_downstream and remote_links.has(first):
				for rp in receiver_link:
					if receiver_link[rp] == remote_links[first] and cells.has(rp):
						starts_downstream = true
						break
			if starts_downstream:
				used[bi] = true
				grew = true
				for c in paths[bi]:
					cells[c] = true
	return cells
