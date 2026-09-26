class_name ProceduralShortcutProbe
extends RefCounted
## Runtime-safe, BOUNDED shortcut probe for Generator V3 (Phase 2B, D96).
##
## Question: "is there a way to solve this puzzle in FEWER flips than the
## intended solution?" The exact answer needs LevelSolver (dev-only, up to 2^n
## states). This probe is the cheap runtime approximation: a beam search over
## flips of the tiles a beam CURRENTLY TOUCHES. Restricting to touched tiles
## loses nothing for a minimal solution (flipping a tile no beam reaches changes
## no simulation result, and the first flipped tile along every beam is touched
## at the start), so the search space is the beam-reachable one, kept small by a
## width cap, a total simulation budget, and progress ordering.
##
## Ordering: shortcuts that matter (a stray beam joining a LATER part of the
## intended route) show up as a jump in how many of the intended solved-state
## beam cells a state lights, so that overlap leads the score; the generic
## progress score (targets/switches/receivers reached) breaks ties.
##
## Uses ONLY LaserSystem via ProceduralComplexity (rules 1/3/9) - never
## LevelSolver/LevelValidator. A negative result means "no shortcut found within
## the budget", never "proved none": the dev-time audit remains the proof.

const DEFAULT_SIM_BUDGET := 420
const DEFAULT_WIDTH := 12


## `solution_orientations` = the intended solution (may be empty: the overlap term
## then vanishes). Returns {shortcut: bool, depth: int, sims: int, exhausted: bool}.
## `depth` = flips of the cheapest shortcut found (only meaningful if shortcut).
static func probe(level: LevelData, intended_moves: int, solution_orientations: Dictionary = {}, sim_budget: int = DEFAULT_SIM_BUDGET, width: int = DEFAULT_WIDTH) -> Dictionary:
	var rotatable: Dictionary = ProceduralComplexity.rotatable_types(level) # pos -> tile_type (Fusion taps rotate 4-state)
	var start: Dictionary = level.get_initial_tile_orientations()
	var sims := 1
	var first: Dictionary = LaserSystem.simulate_until_stable(level, start)
	if first["solved"]:
		return {"shortcut": true, "depth": 0, "sims": sims, "exhausted": false}
	var intended_cells := {}
	if not solution_orientations.is_empty():
		var solved: Dictionary = start.duplicate()
		for p in solution_orientations:
			solved[p] = solution_orientations[p]
		sims += 1
		for beam in LaserSystem.simulate_until_stable(level, solved)["beams"]:
			intended_cells.merge(ProceduralComplexity.touched_cells(beam))
	var seen := {_key(start, rotatable): true}
	var frontier: Array = [{"o": start, "res": first}]
	for depth in range(1, intended_moves):
		var next: Array = []
		for node in frontier:
			var touched := _touched(node["res"])
			for pos in touched:
				if not rotatable.has(pos):
					continue
				var o2: Dictionary = node["o"].duplicate()
				o2[pos] = ProceduralComplexity.tap_orientation(rotatable[pos], o2[pos])
				var key := _key(o2, rotatable)
				if seen.has(key):
					continue
				seen[key] = true
				sims += 1
				var res: Dictionary = LaserSystem.simulate_until_stable(level, o2)
				if res["solved"]:
					return {"shortcut": true, "depth": depth, "sims": sims, "exhausted": false, "orientations": o2}
				var lit := _touched(res)
				var overlap := 0
				for c in lit:
					if intended_cells.has(c):
						overlap += 1
				next.append({"o": o2, "res": res, "score": overlap * 10 + ProceduralComplexity.progress_score(level, res)})
				if sims >= sim_budget:
					return {"shortcut": false, "depth": -1, "sims": sims, "exhausted": true}
		if next.is_empty():
			break
		next.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
		frontier = next.slice(0, width)
	return {"shortcut": false, "depth": -1, "sims": sims, "exhausted": false}


static func _touched(res: Dictionary) -> Dictionary:
	var cells := {}
	for beam in res["beams"]:
		cells.merge(ProceduralComplexity.touched_cells(beam))
	return cells


static func _key(o: Dictionary, rotatable: Dictionary) -> String:
	var s := ""
	var keys := rotatable.keys()
	keys.sort()
	for p in keys:
		s += str(int(o[p]))
	return s
