class_name ProceduralComposerV3
extends RefCounted
## Layout composer for Generator V3 progression (Phase 2B, D96): realises the
## line tree ProceduralFragmentsV3 planned on a portrait board, WITHOUT any
## hand-placed coordinates. Beams are laid one route at a time through
## ProceduralBoardV3's Cursor primitives (mirror orientations are computed from
## GridTypes.reflect there - no second reflection table):
##
##   - a randomised, budgeted depth-first router picks the turn cells of each
##     "turn slot" (beams may only cross PERPENDICULAR, so two beams never share
##     a cell along one axis);
##   - straight elements (filter, gate, splitter, target, ...) land on the ray
##     that follows the last turn;
##   - portals jump to a random free exit; hops (receiver -> remote emitter) start
##     a new route anywhere free; prisms/splitters spawn child routes built
##     immediately; gates spawn their switch route immediately;
##   - shared-mirror / shared-one-way "joins" are goal-directed walks that must
##     arrive at the shared tile through its OTHER channel (disjoint arms);
##   - every placement group is retried from a board snapshot, so a dead end
##     rolls back locally instead of failing the whole level.
##
## Geometry never widens the board or shrinks cells: a plan that cannot be
## placed reports `failure` and the generator tries its next attempt.

const _U := GridTypes.Direction.UP
const _R := GridTypes.Direction.RIGHT
const _D := GridTypes.Direction.DOWN
const _L := GridTypes.Direction.LEFT

const WALK_BUDGET := 120
const OP_BUDGET := 500 # per restart
const RESTARTS := 8
const GROUP_TRIES := 3
const FEEDER_TRIES := 6
const CHILD_TRIES := 3
const ROOT_TRIES := 10
const _STRAIGHT := ["filter", "gate", "portal", "splitter", "hold", "target", "switch", "hop", "prism", "fusion"]

var board: ProceduralBoardV3
var rng: RandomNumberGenerator
var w: int
var h: int
var shared: Dictionary = {}
## Fusion nodes under construction (Fusion Phase 2, D100): fid -> {cell, dout, sides (input sides still
## to be joined), colors (input colours so far), pending, out (the output line), n_in}. The output line
## is built the moment the LAST input has joined, so every input colour is known when the fused colour
## is computed.
var fusions: Dictionary = {}
## Beam colours already produced by an emitter/remote/prism channel/filter. A filter
## always takes an UNUSED colour, so no other beam can satisfy its target colour
## (the "colour must be unobtainable except through its filter" rule, D96).
var used_colors: Dictionary = {}
var _prev: String = "start"
var _line_seq: int = 0
## 1.0 = strongly prefer short hops (dense boards); 0.0 = uniform over all hops.
static var compact_alpha: float = -1.0 # dev override; < 0 = per-plan (plan.params["alpha"])
var alpha: float = 1.0
var ops: int = 0
var _walk_left: int = 0


## Lays the plan out on a fresh width x height board. Placement time is heavy-tailed
## (a typical success needs a few hundred router steps, a dead end can burn
## thousands), so the build RESTARTS from scratch several times with a small
## step budget each instead of grinding through one deep search.
static func build(plan: ProceduralPlanV3, rng_in: RandomNumberGenerator, width: int, height: int) -> ProceduralBoardV3:
	var total_ops := 0
	var c: ProceduralComposerV3
	for _restart in range(RESTARTS):
		c = ProceduralComposerV3.new()
		c.rng = rng_in
		c.w = width
		c.h = height
		c.board = ProceduralBoardV3.new(width, height, false)
		c.alpha = compact_alpha if compact_alpha >= 0.0 else float(plan.params.get("alpha", 1.0))
		var built := c._build_line(plan.lines[0], null, GridTypes.BeamColor.WHITE, ROOT_TRIES)
		total_ops += c.ops
		if built and c.board.failure == "":
			last_ops = total_ops
			return c.board
	last_ops = total_ops
	c.board.fail("composer could not place the plan")
	return c.board

# --- Geometry helpers -----------------------------------------------------------

func _in(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h


static func _axis(dir: int) -> int:
	return 1 if dir == _L or dir == _R else 2


static func _vec(dir: int) -> Vector2i:
	return GridTypes.direction_vector(dir)


static func _perp(dir: int) -> Array:
	return [_L, _R] if dir == _U or dir == _D else [_U, _D]


static func _opp(dir: int) -> int:
	match dir:
		_U:
			return _D
		_D:
			return _U
		_L:
			return _R
	return _L


func _blocked(c: Vector2i, tt: Dictionary) -> bool:
	return board.tile_cells.has(c) or tt.has(c)


func _axis_at(c: Vector2i, ta: Dictionary) -> int:
	return int(board.path_axis.get(c, 0)) | int(ta.get(c, 0))


func _turnable(c: Vector2i, tt: Dictionary, ta: Dictionary) -> bool:
	return not board.tile_cells.has(c) and not tt.has(c) and not board.path_cells.has(c) and not ta.has(c)


## Distances k >= 1 along (pos, dir) at which a tile may land (free cell, every
## cell before it passable), stopping at the first obstacle.
func _land_list(pos: Vector2i, dir: int, tt: Dictionary = {}, ta: Dictionary = {}) -> Array[int]:
	var out: Array[int] = []
	var step := _vec(dir)
	var ax := _axis(dir)
	var k := 1
	while true:
		var c := pos + step * k
		if not _in(c) or _blocked(c, tt):
			break
		if (_axis_at(c, ta) & ax) != 0:
			break
		if _turnable(c, tt, ta):
			out.append(k)
		k += 1
	return out


## A beam that ends a line must leave the board, meet a blocker, or be capped by
## one: any OTHER tile in front of it (mirror, receiver, switch, portal, ...) would
## let the stray beam keep going and power something the plan never meant. A beam
## path in front is not allowed either.
func _end_ok(cell: Vector2i, dir: int) -> bool:
	var nxt := cell + _vec(dir)
	if not _in(nxt):
		return true
	if board.tile_cells.has(nxt):
		return board.tile_cells[nxt] == "blocker"
	return not board.path_cells.has(nxt)


func _cap(cur: ProceduralBoardV3.Cursor) -> void:
	var nxt := cur.pos + _vec(cur.dir)
	if not _end_ok(cur.pos, cur.dir):
		board.fail("line end at %s would leak into %s" % [cur.pos, nxt])
		return
	if not _in(nxt) or board.tile_cells.has(nxt):
		return
	board.tiles.append(TilePlacement.make_blocker(nxt))
	board.tile_cells[nxt] = "blocker"


## Caps one unused prism channel; false when the cell in front is a non-blocker tile
## or a beam path (the channel would leak).
func _cap_side(cell: Vector2i, dir: int) -> bool:
	if not _end_ok(cell, dir):
		return false
	var c := cell + _vec(dir)
	if _in(c) and not board.tile_cells.has(c):
		board.tiles.append(TilePlacement.make_blocker(c))
		board.tile_cells[c] = "blocker"
	return true


## The wrong-state branch of a splitter: capped when possible, never a failure.
func _cap_wrong(cell: Vector2i, dir: int) -> void:
	var c := cell + _vec(dir)
	if _in(c) and not board.tile_cells.has(c) and not board.path_cells.has(c):
		board.tiles.append(TilePlacement.make_blocker(c))
		board.tile_cells[c] = "blocker"


func _one_way_ok(din: int, dout: int) -> bool:
	var o := ProceduralBoardV3.orientation_for(din, dout)
	return o >= 0 and GridTypes.one_way_reflector_is_reflective(din, o)


func _exhausted() -> bool:
	return ops > OP_BUDGET


# --- Snapshots -------------------------------------------------------------------

func _snap() -> Dictionary:
	return {"b": board.snapshot(), "shared": shared.duplicate(true), "used": used_colors.duplicate(), "fusions": fusions.duplicate(true)}


func _rollback(s: Dictionary) -> void:
	board.restore(s["b"])
	shared = s["shared"].duplicate(true)
	fusions = s["fusions"].duplicate(true)
	used_colors = s["used"].duplicate()


# --- Lines -----------------------------------------------------------------------

## Builds `line`. An "emitter" line places its own emitter (random free cell and
## facing); every other kind continues from `start` (placed by its parent).
func _build_line(line: Dictionary, start: ProceduralBoardV3.Cursor, color: int, tries: int) -> bool:
	var own: bool = line["src"]["kind"] == "emitter"
	_line_seq += 1
	var line_id := _line_seq
	for _t in range(tries):
		if _exhausted():
			return false
		var s := _snap()
		var cur: ProceduralBoardV3.Cursor
		var c: int = line["src"]["color"] if own else color
		var first_tile := board.tiles.size()
		if own:
			cur = _place_emitter(c)
		else:
			cur = ProceduralBoardV3.Cursor.new(board, start.pos, start.dir)
		if cur != null and board.failure == "" and _run(line["tokens"], 0, cur, c):
			for ti in range(first_tile, board.tiles.size()):
				var tp: Vector2i = board.tiles[ti].position
				if not board.tile_line.has(tp):
					board.tile_line[tp] = line_id
			return true
		if cur == null:
			_note("emitter")
		_rollback(s)
	return false


func _free_cell(c: Vector2i) -> bool:
	return _in(c) and not board.tile_cells.has(c) and not board.path_cells.has(c)


## A random emitter / remote-emitter cell and facing. Sources sit on the board
## edge facing inward whenever possible (nothing can then arrive from behind); a
## source in the open needs a free cell (or an existing blocker) behind it, which
## gets a blocker - a stray beam passing an emitter cell in its own direction would
## otherwise continue as that emitter's beam.
func _random_source_cell() -> Array:
	for i in range(80):
		ops += 1
		var p := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, h - 1))
		if not _free_cell(p):
			continue
		var dir := rng.randi_range(0, 3)
		if _land_list(p, dir).is_empty():
			continue
		var behind := p - _vec(dir)
		if _in(behind):
			if i < 50:
				continue
			if board.tile_cells.has(behind):
				if board.tile_cells[behind] != "blocker":
					continue
			elif board.path_cells.has(behind):
				continue
		return [p, dir]
	return []


func _block_behind(p: Vector2i, dir: int) -> void:
	var behind := p - _vec(dir)
	if _in(behind) and not board.tile_cells.has(behind) and not board.path_cells.has(behind):
		board.tiles.append(TilePlacement.make_blocker(behind))
		board.tile_cells[behind] = "blocker"


func _place_emitter(color: int) -> ProceduralBoardV3.Cursor:
	var src := _random_source_cell()
	if src.is_empty():
		return null
	if color != GridTypes.BeamColor.WHITE:
		used_colors[color] = true
	var cur := board.emitter(src[0], src[1], color)
	_block_behind(src[0], src[1])
	return cur


## Number of straight landings the tokens from `j` need on the ray that follows
## the walk just placed (a portal counts its entry and ends the run).
static func _straight_need(tokens: Array, j: int) -> int:
	var n := 0
	var k := j
	while k < tokens.size():
		var t: Dictionary = tokens[k]
		if not _STRAIGHT.has(t["t"]):
			break
		n += 1
		if t["t"] == "portal" or t["t"] == "switch" or t["t"] == "hop" or t["t"] == "prism" or t["t"] == "fusion":
			break
		if t["t"] == "target" and not t.get("mid", false):
			break
		k += 1
	return n


static func _run_has_hold(tokens: Array, j: int) -> bool:
	var k := j
	while k < tokens.size() and _STRAIGHT.has(tokens[k]["t"]):
		if tokens[k]["t"] == "hold":
			return true
		if tokens[k]["t"] in ["portal", "switch", "hop", "prism", "fusion"]:
			break
		k += 1
	return false


## Places the token list from `i0`, one GROUP at a time (a turn walk, or one
## straight run of elements). Each group is retried a few times from a board
## snapshot and, because the remainder is placed recursively inside the try, a dead
## end later in the line backtracks into an earlier group's random choices instead
## of failing the whole line.
func _run(tokens: Array, i0: int, cur: ProceduralBoardV3.Cursor, color_in: int) -> bool:
	if i0 >= tokens.size():
		return board.failure == ""
	for _try in range(GROUP_TRIES):
		if _exhausted():
			return false
		var s := _snap()
		var c := ProceduralBoardV3.Cursor.new(board, cur.pos, cur.dir)
		var r := _group(tokens, i0, c, color_in)
		if r["ok"] and board.failure == "":
			if r["done"] or _run(tokens, r["next"], c, r["color"]):
				return true
		_rollback(s)
	return false


## {ok, next, color, done}: `done` = the line ended inside this group (its
## children, hop continuation or join tail were already built).
func _group(tokens: Array, i: int, cur: ProceduralBoardV3.Cursor, color_in: int) -> Dictionary:
	var color := color_in
	var t: Dictionary = tokens[i]
	var fail := {"ok": false, "next": i, "color": color, "done": false}
	if t["t"] == "turn":
		var kinds: Array = []
		var nodes: Array = []
		var share_id := ""
		var share_kind := "mirror"
		var share_node := ""
		var j := i
		var first := true
		while j < tokens.size() and tokens[j]["t"] == "turn" and (first or tokens[j].get("attach", false)):
			var tk: Dictionary = tokens[j]
			first = false
			for _n in range(int(tk["n"])):
				kinds.append(tk["kind"])
				nodes.append(tk.get("id", ""))
			if tk.has("share"):
				share_id = tk["share"]
				share_kind = tk.get("share_kind", "mirror")
				share_node = tk.get("share_id", "")
			j += 1
		if share_id != "" and not kinds.is_empty() and share_kind == "one_way":
			kinds[-1] = "one_way"
			nodes[-1] = share_node
		var next: Dictionary = tokens[j] if j < tokens.size() else {}
		if next.get("t", "") == "join":
			var ok_join := _run_join(kinds, nodes, tokens, j, cur, color)
			return {"ok": ok_join, "next": tokens.size(), "color": color, "done": true}
		if next.get("t", "") == "fjoin":
			var ok_fjoin := _run_fjoin(kinds, nodes, tokens, j, cur, color)
			return {"ok": ok_fjoin, "next": tokens.size(), "color": color, "done": true}
		var need := _straight_need(tokens, j) + (1 if _run_needs_tail(tokens, j) else 0)
		var axis_req := 2 if _run_has_hold(tokens, j) else 0
		var steps = _walk(cur, kinds, need, axis_req, {})
		if steps == null:
			_note("walk n=%d need=%d prev=%s" % [kinds.size(), need, _prev])
			return fail
		if not _commit(cur, steps, nodes, share_id, share_kind):
			_note("commit")
			return fail
		return {"ok": true, "next": j, "color": color, "done": false}

	if not _STRAIGHT.has(t["t"]):
		board.fail("unexpected token %s" % t["t"])
		return fail

	# One straight run: reserve a landing cell per token first, then place them.
	var run: Array = []
	var k := i
	while k < tokens.size() and _STRAIGHT.has(tokens[k]["t"]):
		run.append(tokens[k])
		var tt_name: String = tokens[k]["t"]
		k += 1
		if tt_name in ["portal", "switch", "hop", "prism", "fusion"] or (tt_name == "target" and not run[-1].get("mid", false)):
			break
	var ends: bool = run[-1]["t"] in ["switch", "hop", "prism", "fusion"] or (run[-1]["t"] == "target" and not run[-1].get("mid", false))
	var cells := _pick_cells(cur, run.size(), ends, _run_needs_tail(tokens, i), run[-1]["t"] == "fusion")
	if cells.is_empty():
		_note("cells run=%d" % run.size())
		return fail
	var deferred: Array = []
	var idx := 0
	for tk in run:
		var cell: Vector2i = cells[idx]
		idx += 1
		match tk["t"]:
			"filter":
				var fc := _unobtainable_color(color)
				if fc < 0:
					board.fail("no unobtainable filter colour left")
					return fail
				used_colors[fc] = true
				cur.to_filter(cell, fc, tk["id"])
				color = fc
			"gate":
				cur.to_gate(cell, tk["gate"], tk["id"])
				if tk.has("feeder"):
					deferred.append({"kind": "emitter_line", "line": tk["feeder"]})
			"hold":
				cur.to_one_way_hold(cell, tk["id"])
			"target":
				cur.to_target(cell, color, tk["id"])
			"portal":
				var need_after := _straight_need(tokens, k)
				if not _place_portal(cur, cell, tk["id"], need_after):
					_note("portal")
					return fail
			"splitter":
				var branch := _place_splitter(cur, cell, tk["id"], tk["branch"], color)
				if branch == null:
					_note("splitter")
					return fail
				deferred.append({"kind": "line", "line": tk["branch"], "cursor": branch, "color": color})
			"switch":
				cur.to_switch(cell, tk["gate"], tk["id"])
			"hop":
				cur.to_receiver(cell, tk["link"], tk["rid"])
			"prism":
				if not _place_prism(cur, cell, tk, color):
					_note("prism")
					return fail
			"fusion":
				if not _place_fusion(cur, cell, tk, color):
					_note("fusion")
					return fail
				for f in tk["feeders"]:
					deferred.append({"kind": "emitter_line", "line": f})
	if board.failure != "":
		return fail
	for job in deferred:
		var ok := false
		if job["kind"] == "emitter_line":
			ok = _build_line(job["line"], null, GridTypes.BeamColor.WHITE, FEEDER_TRIES)
		else:
			ok = _build_line(job["line"], job["cursor"], job["color"], CHILD_TRIES)
		if not ok:
			_note("child_line")
			return fail
	var last: Dictionary = run[-1]
	if ends:
		if last["t"] != "prism" and last["t"] != "fusion":
			_cap(cur)
		if last["t"] == "fusion" and not last["feeders"].is_empty() and int(fusions[last["fid"]]["pending"]) != 0:
			board.fail("fusion did not receive all its inputs")
			return fail
		if last["t"] == "hop":
			return {"ok": _continue_hop(last) and board.failure == "", "next": tokens.size(), "color": color, "done": true}
		return {"ok": board.failure == "", "next": tokens.size(), "color": color, "done": true}
	_prev = last["t"]
	return {"ok": true, "next": k, "color": color, "done": false}


## Picks `count` ascending landing cells on the current ray (random, non-adjacent
## allowed). The last one must satisfy _end_ok when the run ends the line.
func _pick_cells(cur: ProceduralBoardV3.Cursor, count: int, ends: bool, tail: bool = false, fusion_last: bool = false) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var list := _land_list(cur.pos, cur.dir)
	if list.size() < count + (1 if tail else 0):
		return out
	var step := _vec(cur.dir)
	for _try in range(10):
		var idxs: Array = range(list.size())
		_shuffle(idxs)
		_bias_indices(idxs)
		var pick := idxs.slice(0, count)
		pick.sort()
		if tail and pick[-1] >= list.size() - 1:
			continue
		var cells: Array[Vector2i] = []
		for ix in pick:
			cells.append(cur.pos + step * list[ix])
		if fusion_last:
			# The beam ENDS at the node (no end-cap rule) but must leave one empty cell before it, so
			# the input path can be cut for the per-input ablation check.
			var prev_k: int = 0 if count == 1 else int(list[pick[-2]])
			if int(list[pick[-1]]) - prev_k < 2:
				continue
			return cells
		if not ends or _end_ok(cells[-1], cur.dir):
			return cells
	return out


# --- Turn walks -------------------------------------------------------------------

## Randomised DFS over turn cells. Returns the steps [{cell, dir, kind}] or null.
func _walk(cur: ProceduralBoardV3.Cursor, kinds: Array, need: int, axis_req: int, goal: Dictionary) -> Variant:
	var steps: Array = []
	_walk_left = WALK_BUDGET
	if _dfs(cur.pos, cur.dir, 0, kinds, need, axis_req, goal, {}, {}, steps):
		return steps
	return null


func _dfs(pos: Vector2i, dir: int, i: int, kinds: Array, need: int, axis_req: int, goal: Dictionary, tt: Dictionary, ta: Dictionary, steps: Array) -> bool:
	ops += 1
	_walk_left -= 1
	if _walk_left <= 0 or ops > OP_BUDGET:
		return false
	if i == kinds.size():
		return _final_ok(pos, dir, need, axis_req, goal, tt, ta)
	var step := _vec(dir)
	var ax := _axis(dir)
	var cands: Array = []
	var k := 1
	while true:
		var c := pos + step * k
		if not _in(c) or _blocked(c, tt):
			break
		if (_axis_at(c, ta) & ax) != 0:
			break
		if _turnable(c, tt, ta):
			for nd in _perp(dir):
				cands.append([k, nd])
		k += 1
	if cands.is_empty() and i == 0:
		_note("dfs0_no_cands")
	_bias_short(cands)
	for cd in cands:
		var kk: int = cd[0]
		var nd: int = cd[1]
		if kinds[i] == "one_way" and not _one_way_ok(dir, nd):
			continue
		var c := pos + step * kk
		var nx := c + _vec(nd)
		if not _in(nx) or _blocked(nx, tt) or (_axis_at(nx, ta) & _axis(nd)) != 0:
			continue
		var prev: Dictionary = {}
		for m in range(1, kk):
			var mc := pos + step * m
			prev[mc] = ta.get(mc, -1)
			ta[mc] = int(ta.get(mc, 0)) | ax
		tt[c] = true
		steps.append({"cell": c, "dir": nd, "kind": kinds[i]})
		if _dfs(c, nd, i + 1, kinds, need, axis_req, goal, tt, ta, steps):
			return true
		steps.pop_back()
		tt.erase(c)
		for mc in prev:
			if prev[mc] == -1:
				ta.erase(mc)
			else:
				ta[mc] = prev[mc]
	return false


func _final_ok(pos: Vector2i, dir: int, need: int, axis_req: int, goal: Dictionary, tt: Dictionary, ta: Dictionary) -> bool:
	if axis_req != 0 and _axis(dir) != axis_req:
		return false
	if not goal.is_empty():
		if dir != goal["dir"]:
			return false
		var step := _vec(dir)
		var ax := _axis(dir)
		var k := 1
		while true:
			var c := pos + step * k
			if c == goal["cell"]:
				return k >= int(goal.get("gap", 1))
			if not _in(c) or _blocked(c, tt) or (_axis_at(c, ta) & ax) != 0:
				return false
			k += 1
	return _land_list(pos, dir, tt, ta).size() >= need


func _commit(cur: ProceduralBoardV3.Cursor, steps: Array, nodes: Array, share_id: String, share_kind: String) -> bool:
	for si in range(steps.size()):
		var s: Dictionary = steps[si]
		var is_shared := share_id != "" and si == steps.size() - 1
		var din := cur.dir
		if s["kind"] == "one_way":
			cur.to_one_way_turn(s["cell"], s["dir"], nodes[si], is_shared)
		else:
			cur.to_turn(s["cell"], s["dir"], true, false, nodes[si], is_shared)
		if board.failure != "":
			return false
		if is_shared:
			shared[share_id] = {
				"cell": s["cell"], "kind": share_kind, "din": din, "dout": s["dir"],
				"orient": board.solution[board.phys(s["cell"])],
			}
			if not _join_room(shared[share_id]):
				board.fail("no room to join shared tile")
				return false
	return true


# --- Shared tiles ------------------------------------------------------------------

## The (din, dout) pairs a SECOND beam may use through the shared tile: the other
## channel of the same orientation, reflective for one-ways.
func _join_options(sh: Dictionary) -> Array:
	var out: Array = []
	var o: int = sh["orient"]
	for din in [_U, _R, _D, _L]:
		var dout := GridTypes.reflect(din, o)
		var same: bool = din == sh["din"] or (din == _opp(sh["dout"]) and dout == _opp(sh["din"]))
		if same:
			continue
		if sh["kind"] == "one_way" and not GridTypes.one_way_reflector_is_reflective(din, o):
			continue
		out.append([din, dout])
	return out


func _join_room(sh: Dictionary) -> bool:
	for opt in _join_options(sh):
		var back: Vector2i = sh["cell"] - _vec(opt[0])
		var out_ray := _land_list(sh["cell"], opt[1])
		if _in(back) and not board.tile_cells.has(back) and not out_ray.is_empty():
			return true
	return false


func _run_join(kinds: Array, nodes: Array, tokens: Array, j: int, cur: ProceduralBoardV3.Cursor, color: int) -> bool:
	var join: Dictionary = tokens[j]
	if not shared.has(join["share"]):
		board.fail("join before its shared tile")
		return false
	var sh: Dictionary = shared[join["share"]]
	var opts := _join_options(sh)
	_shuffle(opts)
	for opt in opts:
		var s := _snap()
		var goal := {"cell": sh["cell"], "dir": opt[0]}
		var steps = _walk(cur, kinds, 0, 0, goal)
		if steps != null:
			var probe := ProceduralBoardV3.Cursor.new(board, cur.pos, cur.dir)
			if _commit(probe, steps, nodes, "", "mirror"):
				# Ride through the shared tile on this channel.
				if sh["kind"] == "one_way":
					probe.to_one_way_turn(sh["cell"], opt[1], "", true)
				else:
					probe.to_turn(sh["cell"], opt[1], true, false, "", true)
				if board.failure == "" and _run(tokens, j + 1, probe, color):
					return true
		_rollback(s)
	return false


# --- Special placements ------------------------------------------------------------

func _place_portal(cur: ProceduralBoardV3.Cursor, entry: Vector2i, id: String, need_after: int) -> bool:
	var dir := cur.dir
	var cells: Array = []
	for y in range(h):
		for x in range(w):
			var c := Vector2i(x, y)
			ops += 1
			if c == entry or not _free_cell(c):
				continue
			# Not on the same ray beyond the entry (the portal must really jump),
			# and far enough to read as a jump.
			var d := c - entry
			if (dir == _R or dir == _L) and d.y == 0:
				continue
			if (dir == _U or dir == _D) and d.x == 0:
				continue
			if absi(d.x) + absi(d.y) < 3:
				continue
			cells.append(c)
	_shuffle(cells)
	for c in cells:
		if _land_list(c, dir).size() >= maxi(need_after, 1):
			cur.to_portal(entry, c, id, id)
			return board.failure == ""
	return false


func _place_splitter(cur: ProceduralBoardV3.Cursor, cell: Vector2i, id: String, branch: Dictionary, color: int) -> ProceduralBoardV3.Cursor:
	var options: Array = _perp(cur.dir)
	_shuffle(options)
	for bd in options:
		if _land_list(cell, bd).is_empty():
			continue
		var b := cur.to_splitter(cell, bd, id)
		# The other orientation would send the branch the opposite way: a blocker
		# makes that wrong state a visible dead end instead of a stray beam.
		_cap_wrong(cell, _opp(bd))
		return b if board.failure == "" else null
	return null


func _place_prism(cur: ProceduralBoardV3.Cursor, cell: Vector2i, tk: Dictionary, color: int) -> bool:
	if color != GridTypes.BeamColor.WHITE:
		board.fail("prism needs a white beam")
		return false
	var chans: Dictionary = cur.to_prism(cell, tk["id"])
	if board.failure != "" or chans.size() != 3:
		return false
	var turning: Array = []
	for c in [GridTypes.BeamColor.GREEN, GridTypes.BeamColor.BLUE]:
		turning.append(c)
	_shuffle(turning)
	var main_color := -1
	for c in turning:
		var cc: ProceduralBoardV3.Cursor = chans[c]
		if not _land_list(cell, cc.dir).is_empty():
			main_color = c
			break
	if main_color == -1:
		return false
	var used := {main_color: true}
	var jobs: Array = [{"line": tk["main"], "color": main_color}]
	for f in tk.get("feeders", []):
		var picked := -1
		var pool: Array = [GridTypes.BeamColor.RED, GridTypes.BeamColor.GREEN, GridTypes.BeamColor.BLUE]
		_shuffle(pool)
		for c in pool:
			if used.has(c):
				continue
			if not _land_list(cell, chans[c].dir).is_empty():
				picked = c
				break
		if picked == -1:
			return false
		used[picked] = true
		jobs.append({"line": f, "color": picked})
	for c in used:
		used_colors[c] = true
	for c in chans:
		if not used.has(c):
			var cc2: ProceduralBoardV3.Cursor = chans[c]
			if not _cap_side(cell, cc2.dir):
				board.fail("prism channel would leak")
				return false
	if board.failure != "":
		return false
	for job in jobs:
		var cc3: ProceduralBoardV3.Cursor = chans[job["color"]]
		if not _build_line(job["line"], cc3, job["color"], CHILD_TRIES):
			return false
	return true


# --- Fusion nodes (Fusion Phase 2, D100) --------------------------------------------

## True when the input side `sd` of a node at `cell` has an empty stub cell next to it and a turn
## cell at distance >= 2 (a stub cell + a turn cell keep the input path cuttable and reachable).
func _side_room(cell: Vector2i, sd: int) -> bool:
	if not _free_cell(cell + _vec(sd)):
		return false
	for k in _land_list(cell, sd):
		if k >= 2:
			return true
	return false


## Places the Fusion node where line A ends. Chooses the output direction (never the side line A
## arrives from) so that the output has room and every remaining input has a free side. The node's
## OUTPUT line is NOT built here: it is built when the last input has joined (_fusion_complete).
func _place_fusion(cur: ProceduralBoardV3.Cursor, cell: Vector2i, tk: Dictionary, color: int) -> bool:
	if not GridTypes.is_fusion_input_color(color):
		board.fail("fusion input line is not a primary colour")
		return false
	var side_a := _opp(cur.dir)
	var n_extra: int = int(tk["n_in"]) - 1
	var dirs: Array = [_U, _R, _D, _L]
	dirs.erase(side_a)
	_shuffle(dirs)
	for dout in dirs:
		if _land_list(cell, dout).is_empty():
			continue
		var usable: Array = []
		for sd in [_U, _R, _D, _L]:
			if sd != side_a and sd != dout and _side_room(cell, sd):
				usable.append(sd)
		if usable.size() < n_extra:
			continue
		_shuffle(usable)
		cur.to_fusion(cell, dout, tk["fid"])
		if board.failure != "":
			return false
		fusions[tk["fid"]] = {
			"cell": cell, "dout": dout, "sides": usable.slice(0, n_extra), "colors": [color],
			"pending": n_extra, "out": tk["out"], "n_in": int(tk["n_in"]),
		}
		return true
	return false


## A further input line arrives at a placed node: a goal-directed walk ends on one of the node's
## free input sides (at distance >= 2, so one empty stub cell remains). The last arrival builds the
## node's output line.
func _run_fjoin(kinds: Array, nodes: Array, tokens: Array, j: int, cur: ProceduralBoardV3.Cursor, color: int) -> bool:
	var fid: String = tokens[j]["fid"]
	if not fusions.has(fid):
		board.fail("fusion input before its node")
		return false
	if not GridTypes.is_fusion_input_color(color) or fusions[fid]["colors"].has(color):
		board.fail("fusion input colour %d is not a distinct primary" % color)
		return false
	var sides: Array = fusions[fid]["sides"].duplicate()
	_shuffle(sides)
	for sd in sides:
		var s := _snap()
		var cell: Vector2i = fusions[fid]["cell"]
		var goal := {"cell": cell, "dir": _opp(sd), "gap": 2}
		var steps = _walk(cur, kinds, 0, 0, goal)
		if steps != null:
			var probe := ProceduralBoardV3.Cursor.new(board, cur.pos, cur.dir)
			if _commit(probe, steps, nodes, "", "mirror"):
				probe.to_fusion_input(cell)
				if board.failure == "":
					var fs: Dictionary = fusions[fid]
					fs["sides"].erase(sd)
					fs["colors"].append(color)
					fs["pending"] = int(fs["pending"]) - 1
					if int(fs["pending"]) > 0 or _fusion_complete(fid):
						return true
		_rollback(s)
	return false


## Every input is in: the fused colour is now known, so the output line can be built.
func _fusion_complete(fid: String) -> bool:
	var fs: Dictionary = fusions[fid]
	var fused := GridTypes.combine_beam_colors(fs["colors"])
	if fused < 0 or fs["colors"].size() != int(fs["n_in"]):
		board.fail("fusion inputs %s do not fuse" % [fs["colors"]])
		return false
	fs["fused"] = fused
	var out_cursor := ProceduralBoardV3.Cursor.new(board, fs["cell"], fs["dout"])
	return _build_line(fs["out"], out_cursor, fused, CHILD_TRIES) and board.failure == ""


func _continue_hop(tk: Dictionary) -> bool:
	var nxt: Dictionary = tk["next"]
	var hop_color: int = tk["color"]
	if hop_color != GridTypes.BeamColor.WHITE:
		hop_color = hop_color if not used_colors.has(hop_color) else _unobtainable_color(GridTypes.BeamColor.WHITE)
		if hop_color >= 0:
			used_colors[hop_color] = true
		else:
			hop_color = GridTypes.BeamColor.WHITE
	_line_seq += 1
	var hop_line_id := _line_seq
	for _t in range(10):
		if _exhausted():
			return false
		var s := _snap()
		var src := _random_source_cell()
		var first_tile := board.tiles.size()
		if not src.is_empty():
			var cur := board.remote_emitter(src[0], src[1], tk["link"], hop_color, tk["eid"])
			_block_behind(src[0], src[1])
			if board.failure == "" and _run(nxt["tokens"], 0, cur, hop_color):
				for ti in range(first_tile, board.tiles.size()):
					var tp: Vector2i = board.tiles[ti].position
					if not board.tile_line.has(tp):
						board.tile_line[tp] = hop_line_id
				return true
		_rollback(s)
	return false


## Fisher-Yates on the level's own rng (Array.shuffle() would use the global rng
## and break determinism).
func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


## Compact routing: order [distance, dir] candidates by distance x random weight
## so short hops usually win but long ones stay possible (dense boards need the
## short ones; variety needs the long ones).
func _bias_short(cands: Array) -> void:
	for cd in cands:
		cd.append(pow(float(cd[0]), alpha) * (0.4 + rng.randf() * 1.6))
	cands.sort_custom(func(a: Array, b: Array) -> bool: return a[2] < b[2])


## Same idea for landing indices: favour cells close to the previous element.
func _bias_indices(idxs: Array) -> void:
	var keyed: Array = []
	for ix in idxs:
		keyed.append([ix, float(ix + 1) * (0.4 + rng.randf() * 1.6)])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
	for i in range(idxs.size()):
		idxs[i] = keyed[i][0]


## A colour no other beam in the puzzle produces (and different from the beam it
## recolours), or -1 when all three are taken.
func _unobtainable_color(current: int) -> int:
	var options: Array = []
	for c in [GridTypes.BeamColor.RED, GridTypes.BeamColor.GREEN, GridTypes.BeamColor.BLUE]:
		if c != current and not used_colors.has(c):
			options.append(c)
	if options.is_empty():
		return -1
	return options[rng.randi_range(0, options.size() - 1)]


## Dev statistics: why placements failed (read by v3_progression_stats.tscn).
static var fail_stats: Dictionary = {}
static var last_ops: int = 0


static func _note(key: String) -> void:
	fail_stats[key] = int(fail_stats.get(key, 0)) + 1


## True when the straight run starting at token `j` leaves the cursor on the same
## ray (filter, gate, mid target, splitter, hold last): the next walk then needs a
## free cell beyond the last element, so the run must not use the ray's last cell.
static func _run_needs_tail(tokens: Array, j: int) -> bool:
	var k := j
	var last := ""
	while k < tokens.size() and _STRAIGHT.has(tokens[k]["t"]):
		last = tokens[k]["t"]
		if last in ["portal", "switch", "hop", "prism", "fusion"] or (last == "target" and not tokens[k].get("mid", false)):
			return false
		k += 1
	return last != ""


# --- Wrong-ray hardening -------------------------------------------------------------

## After layout: every rotatable mirror's WRONG state throws its beam along a ray.
## If that ray meets any non-blocker tile, or runs along an existing beam corridor,
## a wrong orientation can accidentally re-join the intended route - the source of
## "padding" moves and of shortcuts far below the intended move count. A blocker on
## the first free cell of the ray removes the hazard (the solved beams never touch
## that cell, so the intended solution is unchanged). Returns
## {hazards, repaired, unrepaired}.
static func harden(board: ProceduralBoardV3) -> Dictionary:
	var out := {"hazards": 0, "repaired": 0, "unrepaired": 0, "cross_line": 0, "same_line": 0, "path_overlap": 0}
	var level := board.to_level_data(board.w, board.h)
	var solved: Dictionary = level.get_initial_tile_orientations()
	for p in board.solution:
		solved[p] = board.solution[p]
	var res: Dictionary = LaserSystem.simulate_until_stable(level, solved)
	var kind_at := {}
	for t in board.tiles:
		kind_at[t.position] = t.tile_type
	var seen := {}
	for beam in res["beams"]:
		for seg in beam["segments"]:
			for i in range(1, seg.size() - 1):
				var m: Vector2i = seg[i]
				if not board.solution.has(m) or not kind_at.has(m):
					continue
				var tt: int = kind_at[m]
				if tt != GridTypes.TileType.MIRROR and tt != GridTypes.TileType.ONE_WAY_REFLECTOR:
					continue
				var d: Vector2i = m - seg[i - 1]
				var din := _dir_of(Vector2i(signi(d.x), signi(d.y)))
				var key := "%s|%d" % [m, din]
				if seen.has(key):
					continue
				seen[key] = true
				var wrong: int = ProceduralBoardV3.opposite(board.solution[m])
				var dwrong := din
				if tt == GridTypes.TileType.MIRROR or GridTypes.one_way_reflector_is_reflective(din, wrong):
					dwrong = GridTypes.reflect(din, wrong)
				var hz := _ray_hazard(board, m, dwrong)
				if hz["kind"] == "none":
					continue
				out["hazards"] += 1
				if hz["fix"] != null:
					var fx: Vector2i = hz["fix"]
					board.tiles.append(TilePlacement.make_blocker(fx))
					board.tile_cells[fx] = "blocker"
					out["repaired"] += 1
					continue
				out["unrepaired"] += 1
				if hz["kind"] == "path":
					out["path_overlap"] += 1
				elif board.tile_line.get(hz["cell"], -1) != board.tile_line.get(m, -2):
					out["cross_line"] += 1
				else:
					out["same_line"] += 1
	# Fusion nodes (D100): a node turned to a wrong output direction throws its fused beam along
	# that ray; the same wrong-ray rule as for mirrors applies. The three non-solved directions are
	# checked; a direction that faces one of the node's own input sides just absorbs that input.
	for t in board.tiles:
		if t.tile_type != GridTypes.TileType.FUSION:
			continue
		var fpos: Vector2i = t.position
		var input_sides := {}
		for a in ProceduralFusionCheck._arrivals(res, fpos):
			input_sides[int(String(a).split("|")[0])] = true
		for d in [_U, _R, _D, _L]:
			if d == int(board.solution[fpos]) or input_sides.has(d):
				continue
			var fz := _ray_hazard(board, fpos, d)
			if fz["kind"] == "none":
				continue
			out["hazards"] += 1
			if fz["fix"] != null:
				var fx: Vector2i = fz["fix"]
				board.tiles.append(TilePlacement.make_blocker(fx))
				board.tile_cells[fx] = "blocker"
				out["repaired"] += 1
			else:
				out["unrepaired"] += 1
				out["fusion_unrepaired"] = int(out.get("fusion_unrepaired", 0)) + 1
	return out


static func _dir_of(v: Vector2i) -> int:
	if v.x > 0:
		return GridTypes.Direction.RIGHT
	if v.x < 0:
		return GridTypes.Direction.LEFT
	if v.y > 0:
		return GridTypes.Direction.DOWN
	return GridTypes.Direction.UP


## {kind: "none" | "tile" | "path", cell: hit cell, fix: free cell to block or null}.
static func _ray_hazard(board: ProceduralBoardV3, m: Vector2i, dir: int) -> Dictionary:
	var step := GridTypes.direction_vector(dir)
	var ax := 1 if dir == GridTypes.Direction.LEFT or dir == GridTypes.Direction.RIGHT else 2
	var first_free = null
	var c := m + step
	while c.x >= 0 and c.y >= 0 and c.x < board.w and c.y < board.h:
		if board.tile_cells.has(c):
			if board.tile_cells[c] == "blocker":
				return {"kind": "none", "cell": c, "fix": null}
			return {"kind": "tile", "cell": c, "fix": first_free}
		if (int(board.path_axis.get(c, 0)) & ax) != 0:
			return {"kind": "path", "cell": c, "fix": first_free}
		if first_free == null and not board.path_cells.has(c):
			first_free = c
		c += step
	return {"kind": "none", "cell": c, "fix": null}
