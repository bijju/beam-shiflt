class_name ProceduralBoardV3
extends RefCounted
## Physical layout primitives for Generator V3 (D94). A board collects tiles
## while a Cursor "walks" a beam: it advances along its direction, drops a
## mirror at each turn (the orientation is COMPUTED from the desired
## in/out directions through GridTypes.reflect - no second reflection
## table), and places special tiles on the way. Every placement checks
## bounds and collisions; the first problem is recorded in `failure` and the
## caller rejects the candidate (geometry conflicts are the only reason a
## V3 attempt is retried - difficulty is never obtained by retrying).
##
## All layout coordinates are LOGICAL; the board applies an optional
## vertical flip when writing tiles, so one authored layout yields two
## mirror-image boards and prism channels/colors are always derived from the
## PHYSICAL directions (never assumed).
##
## Solved vs start orientation: every rotatable tile records the orientation
## the solution needs. Its start orientation is the opposite (a required
## move) unless the layout marks it `keep_correct`, in which case it starts
## right and must simply not be disturbed - a plausible-looking tile that is
## not part of the required-move count.

const _R := GridTypes.Direction.RIGHT
const _L := GridTypes.Direction.LEFT
const _U := GridTypes.Direction.UP
const _D := GridTypes.Direction.DOWN

var w: int
var h: int
var flip_v: bool = false

var tiles: Array[TilePlacement] = []
var tile_cells: Dictionary = {}   # physical pos -> role String
var path_cells: Dictionary = {}   # physical pos -> true (empty cells a beam crosses)
var path_axis: Dictionary = {}    # physical pos -> bitmask (1 = horizontal beam, 2 = vertical); the composer only ever crosses perpendicular
var solution: Dictionary = {}     # physical pos -> solved MirrorOrientation (rotatable tiles)
var start: Dictionary = {}        # physical pos -> start MirrorOrientation
var node_tiles: Dictionary = {}   # plan stage id -> Array[Vector2i] (physical)
var tile_line: Dictionary = {}   # physical pos -> id of the composed line that placed the tile (composer only)
var failure: String = ""
var _keep_correct_pool: Array[Vector2i] = []


func _init(width: int, height: int, flip: bool = false) -> void:
	w = width
	h = height
	flip_v = flip


# --- Coordinate transforms -------------------------------------------------

func phys(l: Vector2i) -> Vector2i:
	return Vector2i(l.x, h - 1 - l.y) if flip_v else l


func pdir(d: int) -> int:
	if not flip_v:
		return d
	if d == _U:
		return _D
	if d == _D:
		return _U
	return d


func ldir(pd: int) -> int:
	return pdir(pd) # the vertical flip is its own inverse


func in_bounds_l(l: Vector2i) -> bool:
	return l.x >= 0 and l.y >= 0 and l.x < w and l.y < h


func fail(msg: String) -> void:
	if failure == "":
		failure = msg


## Cheap copy of everything a layout mutates, so the composer can try a
## placement and roll it back (TilePlacement objects are only appended, never
## mutated, until apply_keep_correct() runs at the very end).
func snapshot() -> Dictionary:
	var nodes := {}
	for k in node_tiles:
		nodes[k] = node_tiles[k].duplicate()
	return {
		"tiles": tiles.duplicate(), "tile_cells": tile_cells.duplicate(), "path_cells": path_cells.duplicate(),
		"path_axis": path_axis.duplicate(), "solution": solution.duplicate(), "start": start.duplicate(),
		"node_tiles": nodes, "failure": failure, "pool": _keep_correct_pool.duplicate(), "tile_line": tile_line.duplicate(),
	}


func restore(s: Dictionary) -> void:
	tiles = s["tiles"].duplicate()
	tile_cells = s["tile_cells"].duplicate()
	path_cells = s["path_cells"].duplicate()
	path_axis = s["path_axis"].duplicate()
	solution = s["solution"].duplicate()
	start = s["start"].duplicate()
	var nodes := {}
	for k in s["node_tiles"]:
		nodes[k] = s["node_tiles"][k].duplicate()
	node_tiles = nodes
	failure = s["failure"]
	_keep_correct_pool = s["pool"].duplicate()
	tile_line = s["tile_line"].duplicate()


func _register(node: String, p: Vector2i) -> void:
	if node == "":
		return
	if not node_tiles.has(node):
		node_tiles[node] = []
	node_tiles[node].append(p)


static func orientation_for(din: int, dout: int) -> int:
	for o in [GridTypes.MirrorOrientation.SLASH, GridTypes.MirrorOrientation.BACKSLASH]:
		if GridTypes.reflect(din, o) == dout:
			return o
	return -1


static func opposite(o: int) -> int:
	return GridTypes.MirrorOrientation.BACKSLASH if o == GridTypes.MirrorOrientation.SLASH else GridTypes.MirrorOrientation.SLASH


func _tile_free(p: Vector2i) -> bool:
	return not tile_cells.has(p) and not path_cells.has(p)


# --- Beam sources ----------------------------------------------------------

func emitter(l: Vector2i, dir: int, color: int = GridTypes.BeamColor.WHITE, node: String = "") -> Cursor:
	var p := phys(l)
	if not in_bounds_l(l) or not _tile_free(p):
		fail("emitter cell %s unavailable" % l)
		return Cursor.new(self, l, dir)
	tiles.append(TilePlacement.make_emitter(p, pdir(dir), color))
	tile_cells[p] = "emitter"
	_register(node, p)
	return Cursor.new(self, l, dir)


func remote_emitter(l: Vector2i, dir: int, link: String, color: int, node: String = "") -> Cursor:
	var p := phys(l)
	if not in_bounds_l(l) or not _tile_free(p):
		fail("remote emitter cell %s unavailable" % l)
		return Cursor.new(self, l, dir)
	tiles.append(TilePlacement.make_remote_emitter(p, pdir(dir), link, color))
	tile_cells[p] = "remote"
	_register(node, p)
	return Cursor.new(self, l, dir)


# --- Finishing -------------------------------------------------------------

## Centres the laid-out content (tile bounding box) on the board. A pure translation:
## every tile-to-tile relation is unchanged, and the cells a shifted ray gains or
## loses at the board edge hold no tile, so no beam outcome can change. Composed
## layouts otherwise hug whichever edge their random emitter picked.
func center_content() -> void:
	if tiles.is_empty():
		return
	var lo := Vector2i(w, h)
	var hi := Vector2i(-1, -1)
	for t in tiles:
		lo = Vector2i(mini(lo.x, t.position.x), mini(lo.y, t.position.y))
		hi = Vector2i(maxi(hi.x, t.position.x), maxi(hi.y, t.position.y))
	var d := Vector2i((w - (hi.x - lo.x + 1)) / 2 - lo.x, (h - (hi.y - lo.y + 1)) / 2 - lo.y)
	if d == Vector2i.ZERO:
		return
	for t in tiles:
		t.position += d
	tile_cells = _shift_keys(tile_cells, d)
	path_cells = _shift_keys(path_cells, d)
	path_axis = _shift_keys(path_axis, d)
	solution = _shift_keys(solution, d)
	start = _shift_keys(start, d)
	tile_line = _shift_keys(tile_line, d)
	for k in node_tiles:
		var moved: Array = []
		for p in node_tiles[k]:
			moved.append(p + d)
		node_tiles[k] = moved
	var pool: Array[Vector2i] = []
	for p in _keep_correct_pool:
		pool.append(p + d)
	_keep_correct_pool = pool


static func _shift_keys(src: Dictionary, d: Vector2i) -> Dictionary:
	var out := {}
	for k in src:
		out[k + d] = src[k]
	return out


## Marks up to `count` rotatable, non-shared mirrors (chosen by rng) as
## already-correct at start. Called once, after layout.
func apply_keep_correct(rng: RandomNumberGenerator, count: int) -> void:
	var pool: Array[Vector2i] = _keep_correct_pool.duplicate()
	for i in range(mini(count, pool.size())):
		var idx := rng.randi_range(0, pool.size() - 1)
		var p: Vector2i = pool[idx]
		pool.remove_at(idx)
		start[p] = solution[p]
		for t in tiles:
			if t.position == p:
				t.mirror_orientation = solution[p]


func to_level_data(width: int, height: int) -> LevelData:
	var level := LevelData.new()
	level.grid_width = width
	level.grid_height = height
	level.tiles = tiles
	return level


## ASCII map for dev diagnostics (never shown to players): start state.
static func ascii(level: LevelData) -> String:
	var rows: Array = []
	for y in range(level.grid_height):
		var line: Array = []
		for x in range(level.grid_width):
			line.append(".")
		rows.append(line)
	for t in level.tiles:
		var c := "?"
		var slash: bool = t.mirror_orientation == GridTypes.MirrorOrientation.SLASH
		match t.tile_type:
			GridTypes.TileType.EMITTER:
				c = ">^v<"[[GridTypes.Direction.RIGHT, GridTypes.Direction.UP, GridTypes.Direction.DOWN, GridTypes.Direction.LEFT].find(t.direction)]
			GridTypes.TileType.REMOTE_EMITTER:
				c = "x"
			GridTypes.TileType.MIRROR:
				c = ("/" if slash else "\\") if t.rotatable else ("s" if slash else "b")
			GridTypes.TileType.SPLITTER:
				c = "Y" if slash else "y"
			GridTypes.TileType.ONE_WAY_REFLECTOR:
				c = "O" if slash else "o"
			GridTypes.TileType.TARGET:
				c = "T"
			GridTypes.TileType.FILTER:
				c = "F"
			GridTypes.TileType.PORTAL:
				c = "P"
			GridTypes.TileType.SWITCH:
				c = "S"
			GridTypes.TileType.GATE:
				c = "G"
			GridTypes.TileType.PRISM:
				c = "V"
			GridTypes.TileType.FUSION:
				c = "@"
			GridTypes.TileType.BEAM_RECEIVER:
				c = "R"
			GridTypes.TileType.BLOCKER:
				c = "#"
			GridTypes.TileType.HAZARD:
				c = "!"
		rows[t.position.y][t.position.x] = c
	var out: Array[String] = []
	for line in rows:
		out.append("".join(line))
	return "\n".join(out)


# --- Cursor ----------------------------------------------------------------

class Cursor extends RefCounted:
	var board: ProceduralBoardV3
	var pos: Vector2i   # logical
	var dir: int        # logical

	func _init(b: ProceduralBoardV3, p: Vector2i, d: int) -> void:
		board = b
		pos = p
		dir = d

	func _step() -> Vector2i:
		return GridTypes.direction_vector(dir)

	## Advances so that the NEXT cell along `dir` is `cell`, crossing (and
	## reserving as beam path) the empty cells in between. Returns false and
	## records a failure if `cell` is not straight ahead or a tile is in the way.
	func _approach(cell: Vector2i, what: String) -> bool:
		if board.failure != "":
			return false
		if not board.in_bounds_l(cell):
			board.fail("%s at %s is out of bounds" % [what, cell])
			return false
		var step := _step()
		var delta := cell - pos
		var k := 0
		if step.x != 0:
			k = delta.x * step.x if delta.y == 0 else 0
		else:
			k = delta.y * step.y if delta.x == 0 else 0
		if k < 1:
			board.fail("%s at %s is not straight ahead of %s dir %d" % [what, cell, pos, dir])
			return false
		for _i in range(k - 1):
			pos += step
			var pp := board.phys(pos)
			if board.tile_cells.has(pp):
				board.fail("beam path crosses %s at %s" % [board.tile_cells[pp], pos])
				return false
			board.path_cells[pp] = true
			board.path_axis[pp] = board.path_axis.get(pp, 0) | (1 if step.x != 0 else 2)
		return true

	func _land(cell: Vector2i, what: String) -> bool:
		if not _approach(cell, what):
			return false
		var pp := board.phys(cell)
		if not board._tile_free(pp):
			board.fail("%s at %s collides" % [what, cell])
			return false
		pos = cell
		return true

	## Rotatable (or fixed) mirror at `cell`; the beam leaves in `new_dir`.
	## `shared`: several routes may use this cell; the first creates the
	## tile, later ones must want the same orientation.
	func to_turn(cell: Vector2i, new_dir: int, rotatable: bool = true, keep_correct: bool = false, node: String = "", shared: bool = false) -> Cursor:
		var din := board.pdir(dir)
		var dout := board.pdir(new_dir)
		var o := ProceduralBoardV3.orientation_for(din, dout)
		var pp := board.phys(cell)
		if shared and board.tile_cells.get(pp, "") == "shared_mirror":
			if not _approach(cell, "shared mirror"):
				return self
			if o != board.solution.get(pp, -2):
				board.fail("shared mirror at %s needs two different orientations" % cell)
			pos = cell
			dir = new_dir
			return self
		if o < 0:
			board.fail("mirror at %s cannot turn dir %d to %d" % [cell, dir, new_dir])
			return self
		if not _land(cell, "mirror"):
			return self
		var start_o := o
		if rotatable:
			board.solution[pp] = o
			start_o = o if keep_correct else ProceduralBoardV3.opposite(o)
			board.start[pp] = start_o
			if not keep_correct and not shared:
				pass
			if not shared:
				board._keep_correct_pool.append(pp)
		board.tiles.append(TilePlacement.make_mirror(pp, start_o, rotatable))
		board.tile_cells[pp] = "shared_mirror" if shared else "mirror"
		board._register(node, pp)
		dir = new_dir
		return self

	func to_splitter(cell: Vector2i, branch_dir: int, node: String = "") -> Cursor:
		var o := ProceduralBoardV3.orientation_for(board.pdir(dir), board.pdir(branch_dir))
		if o < 0:
			board.fail("splitter at %s cannot branch dir %d to %d" % [cell, dir, branch_dir])
			return Cursor.new(board, cell, branch_dir)
		if not _land(cell, "splitter"):
			return Cursor.new(board, cell, branch_dir)
		var pp := board.phys(cell)
		board.solution[pp] = o
		board.start[pp] = ProceduralBoardV3.opposite(o)
		board.tiles.append(TilePlacement.make_splitter(pp, ProceduralBoardV3.opposite(o), true))
		board.tile_cells[pp] = "splitter"
		board._register(node, pp)
		return Cursor.new(board, cell, branch_dir) # this cursor continues straight

	## One-way reflector used as a turn (the beam reflects). Shared cells
	## behave like shared mirrors.
	func to_one_way_turn(cell: Vector2i, new_dir: int, node: String = "", shared: bool = false) -> Cursor:
		var din := board.pdir(dir)
		var o := ProceduralBoardV3.orientation_for(din, board.pdir(new_dir))
		var pp := board.phys(cell)
		if o < 0 or not GridTypes.one_way_reflector_is_reflective(din, o):
			board.fail("one-way at %s cannot reflect dir %d to %d" % [cell, dir, new_dir])
			return self
		if shared and board.tile_cells.get(pp, "") == "shared_one_way":
			if not _approach(cell, "shared one-way"):
				return self
			if o != board.solution.get(pp, -2):
				board.fail("shared one-way at %s needs two orientations" % cell)
			pos = cell
			dir = new_dir
			return self
		if not _land(cell, "one-way"):
			return self
		board.solution[pp] = o
		board.start[pp] = ProceduralBoardV3.opposite(o)
		board.tiles.append(TilePlacement.make_one_way_reflector(pp, ProceduralBoardV3.opposite(o), true))
		board.tile_cells[pp] = "shared_one_way" if shared else "one_way"
		board._register(node, pp)
		dir = new_dir
		return self

	## The beam PASSES through a shared one-way (created earlier by another
	## route) - its solved orientation must let this direction through.
	func to_one_way_pass(cell: Vector2i, node: String = "") -> Cursor:
		var pp := board.phys(cell)
		if not _approach(cell, "one-way pass"):
			return self
		if board.tile_cells.get(pp, "") != "shared_one_way":
			board.fail("one-way pass at %s has no shared one-way" % cell)
			return self
		if GridTypes.one_way_reflector_is_reflective(board.pdir(dir), board.solution[pp]):
			board.fail("one-way at %s reflects the passing beam" % cell)
			return self
		pos = cell
		board._register(node, pp)
		return self

	## A single-beam One-Way the beam must PASS in the solved state (its start
	## is the reflecting orientation). Not ablation-load-bearing by nature
	## (removing a tile the beam passes changes nothing) - the required move is
	## what is load-bearing. Only UP/DOWN/LEFT beams can pass; LEFT ignores
	## orientation entirely, so it is rejected as a pointless "decision".
	func to_one_way_hold(cell: Vector2i, node: String = "", keep_correct: bool = false) -> Cursor:
		var din := board.pdir(dir)
		if din == ProceduralBoardV3._R or din == ProceduralBoardV3._L:
			board.fail("one-way hold at %s needs a vertical beam" % cell)
			return self
		var solved_o := GridTypes.MirrorOrientation.BACKSLASH if din == ProceduralBoardV3._U else GridTypes.MirrorOrientation.SLASH
		if not _land(cell, "one-way hold"):
			return self
		var pp := board.phys(cell)
		var start_o := solved_o if keep_correct else ProceduralBoardV3.opposite(solved_o)
		board.solution[pp] = solved_o
		board.start[pp] = start_o
		board.tiles.append(TilePlacement.make_one_way_reflector(pp, start_o, true))
		board.tile_cells[pp] = "one_way_hold"
		board._register(node, pp)
		return self

	## Walks onto a tile another route already placed (two routes converging
	## on one target). The beam ends there; nothing is created.
	func to_join(cell: Vector2i, role: String) -> Cursor:
		if not _approach(cell, "join"):
			return self
		if board.tile_cells.get(board.phys(cell), "") != role:
			board.fail("join at %s expected %s" % [cell, role])
			return self
		pos = cell
		return self

	func _place(cell: Vector2i, what: String, role: String, tile: TilePlacement, node: String) -> Cursor:
		if not _land(cell, what):
			return self
		board.tiles.append(tile)
		board.tile_cells[tile.position] = role
		board._register(node, tile.position)
		return self

	func to_filter(cell: Vector2i, color: int, node: String = "") -> Cursor:
		return _place(cell, "filter", "filter", TilePlacement.make_filter(board.phys(cell), color), node)

	func to_switch(cell: Vector2i, gate_id: String, node: String = "") -> Cursor:
		return _place(cell, "switch", "switch", TilePlacement.make_switch(board.phys(cell), gate_id), node)

	func to_gate(cell: Vector2i, gate_id: String, node: String = "") -> Cursor:
		return _place(cell, "gate", "gate", TilePlacement.make_gate(board.phys(cell), gate_id, false), node)

	func to_receiver(cell: Vector2i, link: String, node: String = "") -> Cursor:
		return _place(cell, "receiver", "receiver", TilePlacement.make_beam_receiver(board.phys(cell), link), node)

	func to_target(cell: Vector2i, color: int = GridTypes.BeamColor.WHITE, node: String = "") -> Cursor:
		return _place(cell, "target", "target", TilePlacement.make_target(board.phys(cell), color), node)

	func to_blocker(cell: Vector2i, node: String = "") -> Cursor:
		return _place(cell, "blocker", "blocker", TilePlacement.make_blocker(board.phys(cell)), node)

	## Portal pair: beam enters at `entry`, leaves `exit_cell` in the same direction.
	func to_portal(entry: Vector2i, exit_cell: Vector2i, pair_id: String, node: String = "") -> Cursor:
		if not _land(entry, "portal entry"):
			return self
		var pe := board.phys(entry)
		var px := board.phys(exit_cell)
		if not board.in_bounds_l(exit_cell) or not board._tile_free(px) or pe == px:
			board.fail("portal exit %s unavailable" % exit_cell)
			return self
		board.tiles.append(TilePlacement.make_portal(pe, pair_id))
		board.tiles.append(TilePlacement.make_portal(px, pair_id))
		board.tile_cells[pe] = "portal"
		board.tile_cells[px] = "portal"
		board._register(node, pe)
		board._register(node, px)
		pos = exit_cell
		return self

	## Prism: the arriving beam ends here and up to three channel beams
	## leave. Returns { color: Cursor } with each cursor's LOGICAL dir
	## derived from the physical channel direction.
	func to_prism(cell: Vector2i, node: String = "") -> Dictionary:
		var out := {}
		if not _land(cell, "prism"):
			return out
		var pp := board.phys(cell)
		board.tiles.append(TilePlacement.make_prism(pp))
		board.tile_cells[pp] = "prism"
		board._register(node, pp)
		var din := board.pdir(dir)
		for c in [GridTypes.BeamColor.RED, GridTypes.BeamColor.GREEN, GridTypes.BeamColor.BLUE]:
			var pd := GridTypes.prism_output_direction(din, c)
			out[c] = Cursor.new(board, cell, board.ldir(pd))
		return out

	## Beam Fusion Node (Fusion Phase 2, D100): the arriving beam ENDS here and one fused beam
	## leaves toward `out_dir`. The solved orientation is the output Direction; the START is one
	## clockwise tap EARLIER (Fusion rotates 4-state, +1 = clockwise), so a generated node always
	## costs exactly one required move. Computed in PHYSICAL directions so the optional vertical
	## flip cannot invert the tap direction. Returns a cursor for the fused output beam.
	func to_fusion(cell: Vector2i, out_dir: int, node: String = "") -> Cursor:
		if not _land(cell, "fusion"):
			return Cursor.new(board, cell, out_dir)
		var pp := board.phys(cell)
		var solved_o := board.pdir(out_dir)
		var start_o := (solved_o + 3) % 4
		board.solution[pp] = solved_o
		board.start[pp] = start_o
		board.tiles.append(TilePlacement.make_fusion(pp, start_o, true))
		board.tile_cells[pp] = "fusion"
		board._register(node, pp)
		return Cursor.new(board, cell, out_dir)

	## A second/third input beam reaching a Fusion Node another line already placed.
	## The beam ends there; nothing is created.
	func to_fusion_input(cell: Vector2i) -> Cursor:
		return to_join(cell, "fusion")

	## Ends an unused beam: a blocker right ahead (nothing at a board edge).
	func cap(node: String = "") -> void:
		var nxt := pos + _step()
		if not board.in_bounds_l(nxt):
			return
		var pp := board.phys(nxt)
		if board.path_cells.has(pp):
			board.fail("cap at %s sits on a beam path" % nxt)
			return
		if board.tile_cells.has(pp):
			return # a tile already ends/absorbs this beam
		board.tiles.append(TilePlacement.make_blocker(pp))
		board.tile_cells[pp] = "blocker"
		board._register(node, pp)
