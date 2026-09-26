class_name ProceduralMinimality
extends RefCounted
## "Is the intended solution really minimal?" - a runtime-safe GROUP redundancy screen (Selector Phase S3 / generator V5,
## D110). Found by replaying the intended solution through a real GridManager: on ~14% of the hardest unscreened V5 boards the
## puzzle became solved after FEWER taps than intended, because a whole group of required-looking tiles was superfluous (each
## tile alone was still "required" - reverting it broke the board - but reverting the whole group did not). ProceduralComplexity's
## per-tile padding check cannot see that, and the beam-search shortcut probe only reaches shallow depths.
##
## Two screens, both only ever asking the REAL LaserSystem (CLAUDE.md rules 1/3/9):
##   1. LAZY ACTIVATION replay: from the start state, set every intended tile a beam currently touches to its solved
##      orientation, simulate, repeat. That is the order a player who follows the beams would work in. If the board is
##      solved before every intended tile has been set, the untouched rest was superfluous.
##   2. Delta debugging (ddmin) over the intended tiles ordered by that activation stage (then by composed line): try REVERTING
##      chunks to their start orientation; a chunk whose removal still leaves the board solved is a superfluous group. Chunks
##      are halved down to single tiles.
## Both are bounded by a simulation budget; running out reports "not found", never "proved minimal" (dev-time v5_verify and
## the independent replay in the QA tools remain the proof).

const DEFAULT_BUDGET := 900


## `groups`: pos -> group id (ProceduralBoardV3.tile_line), only used to keep a route's tiles adjacent in the ddmin order.
## Returns {cheaper: bool, saved: int, required: int, remaining: int, sims: int, how: String}.
static func find_cheaper(level: LevelData, solution: Dictionary, groups: Dictionary = {}, budget: int = DEFAULT_BUDGET) -> Dictionary:
	var start: Dictionary = level.get_initial_tile_orientations()
	var required: Array = []
	for p in solution:
		if int(start.get(p, -1)) != int(solution[p]):
			required.append(p)
	required.sort()
	var out := {"cheaper": false, "saved": 0, "required": required.size(), "remaining": required.size(), "sims": 0, "how": ""}
	if required.size() < 2:
		return out
	var req_set := {}
	for p in required:
		req_set[p] = true

	# 1. Lazy activation. `stage[p]` = the iteration in which p first became touched (never-touched tiles get the last stage).
	var stage := {}
	var applied := {}
	var x: Dictionary = start.duplicate()
	var sims := 0
	var iteration := 0
	while applied.size() < required.size() and iteration <= required.size():
		var res: Dictionary = LaserSystem.simulate_until_stable(level, x)
		sims += 1
		if res["solved"]:
			out["cheaper"] = true
			out["remaining"] = applied.size()
			out["saved"] = required.size() - applied.size()
			out["sims"] = sims
			out["how"] = "lazy activation solved after %d of %d tiles" % [applied.size(), required.size()]
			return out
		var touched := {}
		for beam in res["beams"]:
			touched.merge(ProceduralComplexity.touched_cells(beam))
		var newly: Array = []
		for p in required:
			if not applied.has(p) and touched.has(p):
				newly.append(p)
		if newly.is_empty():
			break
		for p in newly:
			x[p] = solution[p]
			applied[p] = true
			stage[p] = iteration
		iteration += 1
	for p in required:
		if not stage.has(p):
			stage[p] = iteration + 1

	# 1b. UNIONS OF WHOLE LINES: revert every required tile of 1-3 composed lines at once. A route the plan needs but the finished
	# board bypasses (another beam already opens its Gate, a stray channel feeds its Switch, ...) is a superfluous group that no
	# per-tile check and no position-ordered ddmin chunk reliably isolates.
	if not groups.is_empty():
		var line_tiles := {}
		for p in required:
			var gid = groups.get(p, -1)
			if not line_tiles.has(gid):
				line_tiles[gid] = []
			line_tiles[gid].append(p)
		var line_ids: Array = line_tiles.keys()
		line_ids.sort()
		var union_sims := 0
		for k in range(1, mini(3, line_ids.size() - 1) + 1):
			var combos: Array = _combinations(line_ids.size(), k)
			for combo in combos:
				if union_sims >= 160:
					break
				var reverted := {}
				var reverted_count := 0
				for idx in combo:
					for p in line_tiles[line_ids[idx]]:
						reverted[p] = true
						reverted_count += 1
				var o: Dictionary = start.duplicate()
				for p in required:
					if not reverted.has(p):
						o[p] = solution[p]
				sims += 1
				union_sims += 1
				if LaserSystem.simulate_until_stable(level, o)["solved"]:
					out["cheaper"] = true
					out["remaining"] = required.size() - reverted_count
					out["saved"] = reverted_count
					out["sims"] = sims
					out["how"] = "reverting %d whole line(s) (%d tiles) still solves it" % [k, reverted_count]
					return out

	# 2. ddmin, once per tile ORDER (ddmin only finds a group whose tiles are adjacent in the order it is given, so several
	# orders are tried: activation stage + composed line, activation stage alone, pure position both ways).
	var orders := [
		func(p: Vector2i) -> Array: return [int(stage[p]), int(groups[p]) if groups.has(p) else -1, p.y, p.x],
		func(p: Vector2i) -> Array: return [int(stage[p]), p.y, p.x],
		func(p: Vector2i) -> Array: return [p.x, p.y],
		func(p: Vector2i) -> Array: return [p.y, p.x],
		func(p: Vector2i) -> Array: return [int(groups[p]) if groups.has(p) else -1, int(stage[p]), p.y, p.x],
	]
	# Plus seeded random orders (deterministic: fixed seeds), since a superfluous group need not be adjacent in any structural one.
	var shuffle_rng := RandomNumberGenerator.new()
	var shuffle_keys := {}
	for seed_value in [7, 13, 29, 41, 53, 67]:
		shuffle_rng.seed = seed_value
		var shuffled: Array = required.duplicate()
		for k in range(shuffled.size() - 1, 0, -1):
			var j := shuffle_rng.randi_range(0, k)
			var tmp = shuffled[k]
			shuffled[k] = shuffled[j]
			shuffled[j] = tmp
		var rank := {}
		for idx in range(shuffled.size()):
			rank[shuffled[idx]] = idx
		orders.append(func(p: Vector2i) -> Array: return [int(rank[p])])
	var per_order := maxi(budget / orders.size(), 30)
	for order_fn in orders:
		var keyed: Array = []
		for p in required:
			keyed.append([order_fn.call(p), p])
		keyed.sort_custom(func(a: Array, b: Array) -> bool:
			for i in range(a[0].size()):
				if a[0][i] != b[0][i]:
					return a[0][i] < b[0][i]
			return false)
		var cur: Array = []
		for k in keyed:
			cur.append(k[1])
		var used := 0
		var n := 2
		while cur.size() >= 2 and used < per_order:
			var chunk_size := int(ceil(float(cur.size()) / float(n)))
			var reduced := false
			var i0 := 0
			while i0 < cur.size():
				var o: Dictionary = start.duplicate()
				for j in range(cur.size()):
					if j < i0 or j >= i0 + chunk_size:
						o[cur[j]] = solution[cur[j]]
				sims += 1
				used += 1
				if LaserSystem.simulate_until_stable(level, o)["solved"]:
					cur = cur.slice(0, i0) + cur.slice(i0 + chunk_size)
					n = maxi(n - 1, 2)
					reduced = true
					break
				if used >= per_order:
					break
				i0 += chunk_size
			if reduced:
				continue
			if n >= cur.size():
				break
			n = mini(cur.size(), n * 2)
		if cur.size() < required.size():
			out["cheaper"] = true
			out["remaining"] = cur.size()
			out["saved"] = required.size() - cur.size()
			out["how"] = "ddmin found %d of %d tiles sufficient" % [cur.size(), required.size()]
			break
	out["sims"] = sims
	return out


## All k-element index combinations of 0..n-1 in lexicographic order.
static func _combinations(n: int, k: int) -> Array:
	var out: Array = []
	var idx: Array = []
	for i in range(k):
		idx.append(i)
	while true:
		out.append(idx.duplicate())
		var i := k - 1
		while i >= 0 and idx[i] == n - k + i:
			i -= 1
		if i < 0:
			break
		idx[i] += 1
		for j in range(i + 1, k):
			idx[j] = idx[j - 1] + 1
	return out
