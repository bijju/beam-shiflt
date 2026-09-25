class_name ProceduralFusionCheck
extends RefCounted
## Load-bearing / stability checks for GENERATED Fusion boards (Fusion Node Phase 2, D100).
## Runtime-safe like ProceduralComplexity: only LaserSystem (ablation by rebuilding the level with a
## tile replaced by a blocker), never LevelSolver/LevelValidator (CLAUDE.md rule 9).
##
## For every Fusion Node on the board, in the SOLVED state:
##   - it must be active, and every input must be a distinct primary (no duplicate-colour input);
##   - each input path must be REQUIRED: cutting that one input (a blocker on the cell next to the
##     node on the input side, verified to remove exactly that colour from the node's inputs) must
##     leave the puzzle unsolved - a 2-input node needs both paths, a 3-input node needs R, G and B;
##   - the fused colour must be CONSUMED: a target of exactly that colour, or a Switch/Receiver/Prism
##     the fused beam reaches (a WHITE output needs a Prism, because a WHITE target accepts any beam);
##   - it must not FEED BACK into its own inputs: replacing the node with a blocker must leave the
##     set of (side, colour) arrivals at that cell unchanged. This is the deterministic answer to the
##     Phase 1 concern (Prism/Gate/Receiver cycles): an unstable dependency cycle is REJECTED at
##     generation time instead of being left to LaserSystem's pass cap;
##   - LaserSystem must settle BEFORE the pass cap in the start state, the solved state and in every
##     one-tile-away neighbour of the solved state ("converged" in the simulation result).
##   - SHORTCUT SCREENS (Phase 3, D101), all exact LaserSystem runs on the solved board's one-tap-away
##     neighbourhood: a node turned to any OTHER direction (direct target hit, missing input, an input side
##     turned into the output = "output-side input") must not solve the puzzle, and no other single tile
##     flip may either (a flip that still solves means the tile is not really required - a bypass of the
##     Gate/Prism-channel/Remote/route it sits on); no emitter or Remote Emitter may be composite-coloured
##     (a composite beam must come from a Fusion node - "alternate composite route"); the WHITE-target and
##     WHITE-remote colour bypasses below. Wider (multi-flip) bypasses are the runtime probe's job.
## Fusion removal itself (bypass) is measured by ProceduralComplexity's ablation (fusion is a special
## unit there); this class adds the per-input, colour and stability tests.

const _DIRS := [GridTypes.Direction.UP, GridTypes.Direction.RIGHT, GridTypes.Direction.DOWN, GridTypes.Direction.LEFT]
## Neighbour convergence budget: one simulation per one-tile-away state.
const MAX_NEIGHBOUR_SIMS := 80


## {ok, reasons: Array[String], fusions: Array[Dictionary], neighbour_sims, all_settled}
static func evaluate(level: LevelData, solution: Dictionary) -> Dictionary:
	var reasons: Array[String] = []
	var infos: Array = []
	var fusion_tiles: Array[TilePlacement] = []
	for t in level.tiles:
		if t.tile_type == GridTypes.TileType.FUSION:
			fusion_tiles.append(t)
	var out := {"ok": true, "reasons": reasons, "fusions": infos, "neighbour_sims": 0, "all_settled": true, "max_passes": 0}
	if fusion_tiles.is_empty():
		return out

	var authored: Dictionary = level.get_initial_tile_orientations()
	var solved: Dictionary = authored.duplicate()
	for p in solution:
		solved[p] = solution[p]
	var base: Dictionary = LaserSystem.simulate_until_stable(level, solved)
	var start: Dictionary = LaserSystem.simulate_until_stable(level, authored)
	out["max_passes"] = maxi(int(base["passes"]), int(start["passes"]))
	if not base["converged"]:
		reasons.append("solved state does not settle before the pass cap")
	if not start["converged"]:
		reasons.append("start state does not settle before the pass cap")

	# Stability of the whole neighbourhood a player can reach with one wrong tap.
	var rot: Dictionary = ProceduralComplexity.rotatable_types(level)
	var sims := 0
	for pos in rot:
		if sims >= MAX_NEIGHBOUR_SIMS:
			break
		var alts: Array = []
		if rot[pos] == GridTypes.TileType.FUSION:
			for k in range(1, 4):
				alts.append((int(solved[pos]) + k) % 4)
		else:
			alts.append(ProceduralComplexity.tap_orientation(rot[pos], solved[pos]))
		for a in alts:
			var trial: Dictionary = solved.duplicate()
			trial[pos] = a
			sims += 1
			var nres: Dictionary = LaserSystem.simulate_until_stable(level, trial)
			out["max_passes"] = maxi(int(out["max_passes"]), int(nres["passes"]))
			if not nres["converged"]:
				out["all_settled"] = false
				reasons.append("board does not settle when %s is set to %d" % [pos, a])
			if nres["solved"]:
				reasons.append("shortcut: %s set to %d still solves the board (%s is not required)" % [pos, a, "the node" if rot[pos] == GridTypes.TileType.FUSION else "that tile"])
	out["neighbour_sims"] = sims

	for f in fusion_tiles:
		var info := _check_one(level, f, solved, base, reasons)
		infos.append(info)

	# --- colour bypass guards (a WHITE target / WHITE remote accepts anything) ---
	var bare: LevelData = level.duplicate()
	var kept: Array[TilePlacement] = []
	for t in level.tiles:
		if t.tile_type != GridTypes.TileType.FUSION:
			kept.append(t)
	bare.tiles = kept
	var bare_res: Dictionary = LaserSystem.simulate_until_stable(bare, solved)
	for t in level.tiles:
		if (t.tile_type == GridTypes.TileType.EMITTER or t.tile_type == GridTypes.TileType.REMOTE_EMITTER) and t.color != GridTypes.BeamColor.WHITE and not GridTypes.is_fusion_input_color(t.color):
			reasons.append("source at %s emits a composite colour (must come from a Fusion node)" % t.position)
		if t.tile_type == GridTypes.TileType.REMOTE_EMITTER and t.color == GridTypes.BeamColor.WHITE:
			reasons.append("remote emitter at %s is WHITE (explicit colour required on Fusion boards)" % t.position)
		if t.tile_type == GridTypes.TileType.TARGET and t.required and t.color == GridTypes.BeamColor.WHITE:
			if base["activated_targets"].has(t.position) and not bare_res["activated_targets"].has(t.position):
				reasons.append("WHITE target at %s depends on a Fusion output and would accept any colour" % t.position)
	out["ok"] = reasons.is_empty()
	return out


static func _check_one(level: LevelData, f: TilePlacement, solved: Dictionary, base: Dictionary, reasons: Array[String]) -> Dictionary:
	var pos: Vector2i = f.position
	var fused: int = base["fusion_colors"].get(pos, -1)
	var colors: Array = base["fusion_input_colors"].get(pos, [])
	var sides: Dictionary = base["fusion_input_sides"].get(pos, {})
	var info := {"pos": pos, "fused": fused, "inputs": colors.duplicate(), "input_sides": sides.size(), "inputs_required": 0, "consumer": "", "feedback": false}
	if fused < 0:
		reasons.append("fusion at %s is inactive in the solved state" % pos)
		return info
	var pairs := 0
	for s in sides:
		pairs += sides[s].size()
	if pairs != colors.size():
		reasons.append("fusion at %s receives a duplicate input colour" % pos)

	# --- every input path is required ---
	for side in sides:
		for color in sides[side]:
			var remaining: Array = colors.duplicate()
			remaining.erase(color)
			var cut := _cut_input(level, pos, side, solved, remaining)
			if cut.is_empty():
				reasons.append("input %d of fusion at %s cannot be isolated for the ablation check" % [color, pos])
				continue
			if cut["res"]["solved"]:
				reasons.append("input colour %d of fusion at %s is not required" % [color, pos])
			else:
				info["inputs_required"] += 1

	# --- the fused colour is consumed ---
	var consumer := _consumer(level, pos, fused, base)
	info["consumer"] = consumer
	if consumer == "":
		reasons.append("fused colour %d of fusion at %s is not consumed by a matching target / switch / receiver / prism" % [fused, pos])

	# --- no feedback into its own inputs ---
	var blocked := _with_blocker(level, pos)
	var res_b: Dictionary = LaserSystem.simulate_until_stable(blocked, solved)
	if _arrivals(res_b, pos) != _arrivals(base, pos):
		info["feedback"] = true
		reasons.append("fusion at %s feeds back into its own inputs (unstable dependency cycle)" % pos)
	return info


## The tile that consumes the fused colour: "target" (exact colour), "switch", "receiver" or "prism"
## (the only consumer that makes a WHITE output matter). "" = nothing depends on the colour.
static func _consumer(level: LevelData, pos: Vector2i, fused: int, base: Dictionary) -> String:
	var cells := {}
	for beam in base["beams"]:
		var segs: Array = beam["segments"]
		if not segs.is_empty() and not segs[0].is_empty() and segs[0][0] == pos:
			cells.merge(ProceduralComplexity.touched_cells(beam))
	cells.erase(pos)
	var found := ""
	for t in level.tiles:
		if not cells.has(t.position):
			continue
		match t.tile_type:
			GridTypes.TileType.TARGET:
				if t.required and t.color == fused and fused != GridTypes.BeamColor.WHITE:
					return "target"
			GridTypes.TileType.PRISM:
				if fused == GridTypes.BeamColor.WHITE:
					return "prism"
			GridTypes.TileType.SWITCH:
				if found == "":
					found = "switch"
			GridTypes.TileType.BEAM_RECEIVER:
				if found == "":
					found = "receiver"
	# A switch/receiver only counts as consumer for a composite (non-WHITE) beam: the node then acts
	# as an AND of its inputs; a WHITE beam needs the Prism to make its colour matter.
	if fused != GridTypes.BeamColor.WHITE:
		return found
	return ""


## Rebuilds `level` with exactly ONE input of the node at `pos` removed (a blocker on the first
## free cell of that side, 1..3 cells out) and simulates the solved state. Only a CLEAN cut counts:
## the node must still receive every OTHER input colour and nothing changed for them.
static func _cut_input(level: LevelData, pos: Vector2i, side: int, solved: Dictionary, remaining: Array) -> Dictionary:
	var occupied := {}
	for t in level.tiles:
		occupied[t.position] = true
	var step := GridTypes.direction_vector(side)
	for k in range(1, 4):
		var cell: Vector2i = pos + step * k
		if cell.x < 0 or cell.y < 0 or cell.x >= level.grid_width or cell.y >= level.grid_height:
			break
		if occupied.has(cell):
			continue
		var ablated := _with_blocker(level, cell)
		var res: Dictionary = LaserSystem.simulate_until_stable(ablated, solved)
		var after: Array = res["fusion_input_colors"].get(pos, [])
		if after == remaining:
			return {"level": ablated, "res": res, "cell": cell}
	return {}


## Sorted "side|colour" strings of every beam that ends at `pos`.
static func _arrivals(res: Dictionary, pos: Vector2i) -> Array:
	var out: Array = []
	for beam in res["beams"]:
		for seg in beam["segments"]:
			if seg.size() >= 2 and seg[seg.size() - 1] == pos:
				var prev: Vector2i = seg[seg.size() - 2]
				var d := Vector2i(signi(pos.x - prev.x), signi(pos.y - prev.y))
				var travel := ProceduralComposerV3._dir_of(d)
				out.append("%d|%d" % [GridTypes.opposite_direction(travel), int(beam["color"])])
	out.sort()
	return out


static func _with_blocker(level: LevelData, cell: Vector2i) -> LevelData:
	var copy: LevelData = level.duplicate()
	var kept: Array[TilePlacement] = []
	for t in level.tiles:
		if t.position != cell:
			kept.append(t)
	kept.append(TilePlacement.make_blocker(cell))
	copy.tiles = kept
	return copy
