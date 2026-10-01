class_name TestCase
extends RefCounted
## Base class for tools/tests/cases/test_*.gd. Every method named test_* runs;
## before_each()/after_each() wrap each one. Assertions record failures instead
## of aborting, so one run reports everything. Methods may `await`.

var failures: PackedStringArray = []
var assertions: int = 0
var runner: Node = null  # the running scene root, for tests that need a Node parent


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func ok(cond: bool, msg: String = "") -> void:
	assertions += 1
	if not cond:
		failures.append(msg if msg != "" else "expected true")


func eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	assertions += 1
	if typeof(actual) != typeof(expected) and not (typeof(actual) in [TYPE_INT, TYPE_FLOAT] and typeof(expected) in [TYPE_INT, TYPE_FLOAT]):
		failures.append("%s expected %s (%s) got %s (%s)" % [msg, str(expected), type_string(typeof(expected)), str(actual), type_string(typeof(actual))])
	elif actual != expected:
		failures.append("%s expected %s got %s" % [msg, str(expected), str(actual)])


func near(actual: float, expected: float, eps: float = 0.001, msg: String = "") -> void:
	assertions += 1
	if absf(actual - expected) > eps:
		failures.append("%s expected ~%s got %s" % [msg, str(expected), str(actual)])


func ne(actual: Variant, other: Variant, msg: String = "") -> void:
	assertions += 1
	if actual == other:
		failures.append("%s expected not %s" % [msg, str(other)])


func frames(n: int = 2) -> void:
	for i in n:
		await runner.get_tree().process_frame


func current_scene() -> Node:
	return runner.get_tree().current_scene


## Taps every orientable cell until it matches `solution` (Vector2i -> orientation); returns taps made.
func solve_by_taps(grid: GridManager, solution: Dictionary) -> int:
	var taps := 0
	for pos in solution:
		var guard := 0
		while grid.tile_orientations.get(pos, -1) != solution[pos] and guard < 4:
			grid._on_orientable_tile_clicked(pos)
			taps += 1
			guard += 1
	return taps


## Records every emission of `sig` as an Array of up to 4 args.
func watch(sig: Signal) -> Array:
	var out := []
	sig.connect(func(a = null, b = null, c = null, d = null) -> void: out.append([a, b, c, d]))
	return out


## Frees whatever scene a test navigated to and parks a fresh placeholder as current.
func reset_scene() -> void:
	var tree := runner.get_tree()
	var cur := tree.current_scene
	if cur != null:
		cur.queue_free()
	var ph := Node.new()
	ph.name = "Placeholder"
	tree.root.add_child(ph)
	tree.current_scene = ph


## Presses every enabled, visible button under `root` except those whose name contains a skip token.
func press_all(root: Node, skip: PackedStringArray = PackedStringArray(["Quit", "Exit"])) -> int:
	var n := 0
	for b in root.find_children("*", "BaseButton", true, false):
		var bad := false
		for s in skip:
			if String(b.name).contains(s):
				bad = true
		if bad or b.disabled or not b.is_visible_in_tree():
			continue
		b.pressed.emit()
		n += 1
	return n
