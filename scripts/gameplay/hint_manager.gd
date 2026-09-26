class_name HintManager
extends RefCounted
## Global Hint System (Phase 1, DECISIONS.md D97). One shared component, owned by
## game.gd (a plain RefCounted like TutorialManager - not an autoload, rule 6).
## Level data never owns hint state or HUD positioning.
##
## One request = ONE tile. The hint is derived from a KNOWN solution
## (`solution`: cell -> solved MirrorOrientation) that the caller supplies:
## a procedural generator's `solution_orientations`, or the solver-authored
## table `levels/hint_solutions.json` for handcrafted levels/tutorials. No solver
## ever runs at hint time. Requesting a hint never changes an orientation, a move
## count, a save field or a star result; only the ring on the grid is shown.
##
## Monetization seam: request_hint() only ASKS for permission
## (`permission_provider`, null = free); grant_hint() is what actually reveals a
## tile and is the single function a future rewarded-ad / purchased-hint / QA path
## calls. The puzzle logic never knows where the permission came from.

signal hint_shown(pos: Vector2i)
signal hint_cleared
signal hint_unavailable

const NONE := Vector2i(-1, -1)
const AUTO_CLEAR_SEC := 6.0
const SOLUTION_TABLE_PATH := "res://levels/hint_solutions.json"

var grid: GridManager
## cell -> solved orientation for every REQUIRED rotatable tile (empty = no hint source).
var solution: Dictionary = {}
## Optional Callable(HintManager) -> void. It must eventually call grant_hint().
## Unset = free hints.
var permission_provider: Callable = Callable()
## Tutorial hook: Callable() -> Dictionary {"mode": "free"|"target"|"none", "pos": Vector2i}.
var tutorial_state: Callable = Callable()

var _shown: Dictionary = {}   # cell -> "pending" (hinted, not yet solved) | "resolved"
var _active: Vector2i = NONE
var _token: int = 0
static var _table: Dictionary = {}


func bind(grid_: GridManager) -> void:
	grid = grid_
	if not grid.move_made.is_connected(_on_move_made):
		grid.move_made.connect(_on_move_made)


## New puzzle / Reset / Retry / QA jump: forget history and hide any ring.
func configure(solution_: Dictionary) -> void:
	solution = solution_
	_shown.clear()
	clear_hint()


func has_hint_source() -> bool:
	return not solution.is_empty() or tutorial_state.is_valid()


## Permission step (see the class doc). Returns true if a hint was revealed synchronously.
func request_hint() -> bool:
	if permission_provider.is_valid():
		permission_provider.call(self)
		return false # the provider grants later (e.g. after a reward)
	return grant_hint()


func grant_hint() -> bool:
	var pos: Variant = get_hint_candidate()
	if pos == null:
		hint_unavailable.emit()
		return false
	show_hint(pos)
	return true


## The single tile to hint, or null. Cheap: a handful of dictionary lookups.
func get_hint_candidate() -> Variant:
	if grid == null or grid.level_data == null or grid.is_solved:
		return null
	if tutorial_state.is_valid():
		var st: Dictionary = tutorial_state.call()
		match st.get("mode", "none"):
			"none":
				return null
			"target":
				var tp: Vector2i = st["pos"]
				return tp if grid.has_orientable_tile(tp) else null
	var wrong: Array[Vector2i] = []
	for pos in solution:
		if not grid.has_orientable_tile(pos):
			continue
		if grid.tile_orientations.get(pos, -1) != solution[pos]:
			wrong.append(pos)
	if wrong.is_empty():
		return null
	var fresh: Array[Vector2i] = []
	for p in wrong:
		if not _shown.has(p):
			fresh.append(p)
	if fresh.is_empty():
		# Every wrong tile was already hinted: cycle (they are still wrong).
		_shown.clear()
		fresh = wrong
	return _rank(fresh)[0]


## Priority: (1) wrong tiles a beam touches right now, upstream first (the frontier of
## the current dependency stage); (2) otherwise the wrong tile nearest to any lit cell
## (so a tile behind an unpowered receiver/gate comes after the live ones); ties by
## position. Deterministic; never simply "first grid coordinate".
func _rank(cands: Array[Vector2i]) -> Array[Vector2i]:
	var order := {}
	var i := 0
	for beam in grid.get_last_simulation().get("beams", []):
		for seg in beam["segments"]:
			for c in seg:
				if not order.has(c):
					order[c] = i
					i += 1
	var keyed: Array = []
	for p in cands:
		var key: float
		if order.has(p):
			key = float(order[p])
		else:
			var best := 9999.0
			for c in order:
				best = minf(best, absf(c.x - p.x) + absf(c.y - p.y))
			key = 100000.0 + best * 1000.0
		keyed.append([key + p.y * 0.01 + p.x * 0.0001, p])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var out: Array[Vector2i] = []
	for k in keyed:
		out.append(k[1])
	return out


func show_hint(pos: Vector2i) -> void:
	_active = pos
	_shown[pos] = "pending"
	grid.show_hint_cell(pos)
	AudioManager.play_tutorial_step() # existing UI cue; no new audio asset
	_token += 1
	var my_token := _token
	var tree := grid.get_tree()
	if tree != null:
		tree.create_timer(AUTO_CLEAR_SEC).timeout.connect(func() -> void:
			if my_token == _token and _active != NONE:
				clear_hint())
	hint_shown.emit(pos)


## After a full-screen ad closes: restart the auto-clear timer so the ring is not consumed
## while the ad was up (the hint is granted from the reward callback, before the close).
func rearm() -> void:
	if _active == NONE or grid == null:
		return
	_token += 1
	var my_token := _token
	var tree := grid.get_tree()
	if tree != null:
		tree.create_timer(AUTO_CLEAR_SEC).timeout.connect(func() -> void:
			if my_token == _token and _active != NONE:
				clear_hint())


func clear_hint() -> void:
	_token += 1
	if _active == NONE:
		if grid != null:
			grid.clear_hint_cell()
		return
	_active = NONE
	if grid != null:
		grid.clear_hint_cell()
	hint_cleared.emit()


## A rotation was accepted (tile_orientations is already updated). Rotating the hinted
## tile clears its ring; a tile hinted earlier that is now solved is resolved, and one
## the player later turns back to wrong becomes hintable again.
func _on_move_made() -> void:
	var tapped: Vector2i = grid.last_tap_cell
	for pos in _shown.keys():
		var ok: bool = grid.tile_orientations.get(pos, -1) == solution.get(pos, -2)
		if ok:
			_shown[pos] = "resolved"
		elif _shown[pos] == "resolved":
			_shown.erase(pos)
	if tapped == _active:
		clear_hint()


# --- Solver-authored table (handcrafted levels and tutorials) -----------------------

## key: "c<campaign id>" or "t<tutorial id>". Returns {} when the level has no reliable
## solution (the caller then hides Hint and logs a dev warning).
static func table_solution(key: String) -> Dictionary:
	if _table.is_empty():
		if not FileAccess.file_exists(SOLUTION_TABLE_PATH):
			return {}
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOLUTION_TABLE_PATH))
		if parsed is Dictionary:
			_table = parsed
	var out := {}
	for e in _table.get(key, []):
		out[Vector2i(int(e[0]), int(e[1]))] = int(e[2])
	return out
