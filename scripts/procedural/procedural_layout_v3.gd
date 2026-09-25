class_name ProceduralLayoutV3
extends RefCounted
## Physical layout planner for Generator V3 (D94): turns a ProceduralPlanV3
## into tiles on a portrait board (<= GridManager.MAX_COLUMNS columns, square
## cells, no pixel maths - board size only). Each archetype has ONE reusable
## macro-layout composed from ProceduralBoardV3's stage primitives (turn,
## filter, switch/gate, portal, prism, splitter, receiver/remote, shared
## mirror, shared one-way); the plan's params (colors, mirror-image flip)
## are the only variation. A macro-layout that cannot be placed reports a
## failure and the generator retries - it never widens the board or
## shrinks cells.
##
## Design rules every layout follows:
##  - the solved configuration is built first; start orientations are
##    derived from it (opposite for a required move), never random flips;
##  - every unused prism/splitter channel is capped so no stray beam can
##    reach unrelated tiles;
##  - a shared tile's two beams use DISJOINT arms (an "X" crossing), so one
##    orientation serves both and the other breaks both;
##  - colored targets/emitters stop white/default beams from bypassing the
##    intended color reasoning.

const _R := GridTypes.Direction.RIGHT
const _L := GridTypes.Direction.LEFT
const _U := GridTypes.Direction.UP
const _D := GridTypes.Direction.DOWN

const BOARD_W := 8


static func board_height_for(archetype: String) -> int:
	match archetype:
		"switch_gate_shared", "portal_receiver_remote", "shared_one_way":
			return 10
	return 11


## Returns the populated ProceduralBoardV3 (check `.failure`).
static func build(plan: ProceduralPlanV3, rng: RandomNumberGenerator) -> ProceduralBoardV3:
	var h := board_height_for(plan.archetype)
	var b := ProceduralBoardV3.new(BOARD_W, h, plan.params.get("flip_v", false))
	match plan.archetype:
		"switch_gate_shared":
			_layout_a(b, plan)
		"prism_color_portal":
			_layout_b(b, plan)
		"portal_receiver_remote":
			_layout_c(b, plan)
		"shared_one_way":
			_layout_d(b, plan)
		"splitter_convergence":
			_layout_e(b, plan)
		"mixed_chain":
			_layout_f(b, plan)
		_:
			b.fail("unknown archetype %s" % plan.archetype)
	return b


static func _v(x: int, y: int) -> Vector2i:
	return Vector2i(x, y)


## The prism cursor whose LOGICAL direction is `logical_dir`.
static func _branch(branches: Dictionary, logical_dir: int) -> ProceduralBoardV3.Cursor:
	for color in branches:
		if branches[color].dir == logical_dir:
			return branches[color]
	return null


static func _color_of(branches: Dictionary, logical_dir: int) -> int:
	for color in branches:
		if branches[color].dir == logical_dir:
			return color
	return GridTypes.BeamColor.WHITE


# --- A: Switch -> Gate -> second route, one shared mirror, color filter ------
static func _layout_a(b: ProceduralBoardV3, plan: ProceduralPlanV3) -> void:
	var c: int = plan.params["filter_color"]
	# Beam 1 reaches the shared mirror M along row 4 and leaves upward to the Switch.
	var r1 := b.emitter(_v(0, 1), _R)
	r1.to_turn(_v(1, 1), _D).to_turn(_v(1, 3), _R).to_turn(_v(3, 3), _D).to_turn(_v(3, 4), _R)
	r1.to_turn(_v(4, 4), _U, true, false, "share", true)
	r1.to_switch(_v(4, 2), "gA", "sw")
	r1.cap()
	# Beam 2 reaches M from below (arms disjoint from beam 1) and leaves to the right.
	var r2 := b.emitter(_v(0, 9), _R)
	r2.to_turn(_v(2, 9), _U).to_turn(_v(2, 7), _R).to_turn(_v(4, 7), _U)
	r2.to_turn(_v(4, 4), _R, true, false, "share", true)
	r2.to_filter(_v(5, 4), c, "filt")
	r2.to_gate(_v(6, 4), "gA", "gt")
	r2.to_turn(_v(7, 4), _D).to_turn(_v(7, 6), _L)
	r2.to_target(_v(5, 6), c, "tgt")


# --- B: Prism channels, Filter, Portal --------------------------------------
static func _layout_b(b: ProceduralBoardV3, plan: ProceduralPlanV3) -> void:
	var t := b.emitter(_v(0, 1), _R)
	t.to_turn(_v(2, 1), _D).to_turn(_v(2, 3), _R).to_turn(_v(4, 3), _D).to_turn(_v(4, 4), _R)
	var br := t.to_prism(_v(5, 4), "pr")
	var straight := _branch(br, _R)
	var up := _branch(br, _U)
	var down := _branch(br, _D)
	if straight == null or up == null or down == null:
		b.fail("prism channels missing")
		return
	up.cap()
	# Straight (RED) channel: its own route to a red target.
	straight.to_turn(_v(6, 4), _U).to_turn(_v(6, 2), _R)
	straight.to_target(_v(7, 2), GridTypes.BeamColor.RED, "t1")
	# Turning channel: down, left into the Portal, out far away, Filter, target.
	var branch_color := _color_of(br, _D)
	var out_color: int = GridTypes.BeamColor.GREEN if branch_color == GridTypes.BeamColor.BLUE else GridTypes.BeamColor.BLUE
	down.to_turn(_v(5, 6), _L)
	down.to_portal(_v(3, 6), _v(6, 8), "pB", "pt")
	down.to_filter(_v(5, 8), out_color, "filt")
	down.to_turn(_v(4, 8), _D).to_turn(_v(4, 9), _L)
	down.to_target(_v(2, 9), out_color, "t2")


# --- C: Portal -> Receiver -> Remote Emitter -> Filter -> Target --------------
static func _layout_c(b: ProceduralBoardV3, plan: ProceduralPlanV3) -> void:
	var rc: int = plan.params["remote_color"]
	var fc: int = plan.params["filter_color"]
	var e1 := b.emitter(_v(0, 0), _R)
	e1.to_turn(_v(1, 0), _D).to_turn(_v(1, 1), _R).to_turn(_v(2, 1), _D).to_turn(_v(2, 2), _R).to_turn(_v(3, 2), _D)
	e1.to_portal(_v(3, 4), _v(6, 3), "pC", "pt")
	e1.to_turn(_v(6, 6), _L).to_turn(_v(5, 6), _D).to_turn(_v(5, 8), _L)
	e1.to_receiver(_v(4, 8), "linkC", "rc")
	e1.cap()
	var re := b.remote_emitter(_v(0, 9), _R, "linkC", rc, "re")
	re.to_filter(_v(1, 9), fc, "filt")
	re.to_turn(_v(2, 9), _U).to_turn(_v(2, 5), _R)
	re.to_target(_v(4, 5), fc, "tgt")
	re.cap()


# --- D: shared One-Way, pass vs reflect, false-open gate ----------------------
# OW1 (4,5) is shared: solved = SLASH (A: right->up, B: up->right, disjoint arms).
# Its wrong state BACKSLASH lets B PASS up into the Switch (gate looks open) while
# A is sent down. OW2 (4,1) is a second One-Way A must PASS (BACKSLASH).
# B's pre-route starts correct so B is already flowing at the start.
static func _layout_d(b: ProceduralBoardV3, plan: ProceduralPlanV3) -> void:
	var ca: int = plan.params["color_a"]
	var cb: int = plan.params["color_b"]
	var cf: int = plan.params["filter_color"]
	var bb := b.emitter(_v(7, 9), _L, cb)
	bb.to_turn(_v(6, 9), _U, true, true).to_turn(_v(6, 8), _L, true, true).to_turn(_v(4, 8), _U, true, true)
	bb.to_one_way_turn(_v(4, 5), _R, "ow", true)
	bb.to_filter(_v(5, 5), cf, "filt")
	bb.to_gate(_v(6, 5), "gD", "gt")
	bb.to_turn(_v(7, 5), _D)
	bb.to_portal(_v(7, 6), _v(2, 8), "pD", "pt")
	bb.to_turn(_v(2, 9), _R)
	bb.to_target(_v(4, 9), cf, "tb")
	bb.cap()
	var a := b.emitter(_v(0, 9), _R, ca)
	a.to_turn(_v(1, 9), _U).to_turn(_v(1, 7), _R).to_turn(_v(3, 7), _U).to_turn(_v(3, 5), _R)
	a.to_one_way_turn(_v(4, 5), _U, "ow", true)
	a.to_switch(_v(4, 3), "gD", "sw")
	a.to_one_way_hold(_v(4, 1), "hold")
	a.to_target(_v(4, 0), ca, "ta")


# --- E: converging chains + colour fork ---------------------------------------
# Splitter -> {Switch (opens Gate), Portal -> Receiver (powers Remote)}. The remote
# beam meets a fork mirror: one way detours through the Gate and the Filter the
# target's colour needs; the other reaches the SAME target through a wrong-colour
# Filter (fixed, visible decoy route). Switch-side tile (5,1) and remote tile
# (1,9) start correct.
static func _layout_e(b: ProceduralBoardV3, plan: ProceduralPlanV3) -> void:
	var rcol: int = plan.params["remote_color"]
	var fcol: int = plan.params["filter_color"]
	var wcol: int = plan.params["wrong_color"]
	var t := b.emitter(_v(0, 0), _R)
	t.to_turn(_v(2, 0), _D).to_turn(_v(2, 2), _R).to_turn(_v(3, 2), _D).to_turn(_v(3, 3), _R)
	var down := t.to_splitter(_v(4, 3), _D, "sp")
	t.to_turn(_v(5, 3), _U).to_turn(_v(5, 1), _R, true, true)
	t.to_switch(_v(7, 1), "gE", "sw")
	down.to_turn(_v(4, 5), _R)
	down.to_portal(_v(5, 5), _v(6, 8), "pE", "pt")
	down.to_turn(_v(7, 8), _D)
	down.to_receiver(_v(7, 9), "linkE", "rc")
	down.cap()
	var re := b.remote_emitter(_v(0, 10), _R, "linkE", rcol, "re")
	re.to_turn(_v(1, 10), _U).to_turn(_v(1, 9), _R, true, true)
	re.to_turn(_v(2, 9), _U, true, false, "fork")
	re.to_gate(_v(2, 8), "gE", "gt")
	re.to_filter(_v(2, 7), fcol, "filt")
	re.to_turn(_v(2, 6), _R)
	re.to_target(_v(5, 6), fcol, "tgt")
	re.cap()
	var wrong := ProceduralBoardV3.Cursor.new(b, _v(2, 9), _D)
	wrong.to_turn(_v(2, 10), _R, false)
	wrong.to_filter(_v(3, 10), wcol, "filt2")
	wrong.to_turn(_v(5, 10), _U, false)
	wrong.to_join(_v(5, 6), "target")


# --- F: Prism -> shared One-Way as global decision ------------------------------
# Prism DOWN channel (Z) enters the shared One-Way (4,5) from the left; the RED
# channel goes Portal -> Receiver -> Remote, whose beam enters the same One-Way
# from below. SLASH: Z reflects UP into the Switch, the remote reflects RIGHT
# through Gate + Filter -> target. BACKSLASH: the remote PASSES up, hits the Switch
# itself and reaches the target through the wrong-colour Filter. (1,0) starts correct.
static func _layout_f(b: ProceduralBoardV3, plan: ProceduralPlanV3) -> void:
	var rcol: int = plan.params["remote_color"]
	var fcol: int = plan.params["filter_color"]
	var wcol: int = plan.params["wrong_color"]
	var t := b.emitter(_v(0, 0), _R)
	t.to_turn(_v(1, 0), _D, true, true).to_turn(_v(1, 1), _R).to_turn(_v(2, 1), _D).to_turn(_v(2, 2), _R)
	var br := t.to_prism(_v(3, 2), "pr")
	var straight := _branch(br, _R)
	var up := _branch(br, _U)
	var down := _branch(br, _D)
	if straight == null or up == null or down == null:
		b.fail("prism channels missing")
		return
	up.cap()
	straight.to_turn(_v(6, 2), _D)
	straight.to_portal(_v(6, 4), _v(1, 7), "pF", "pt")
	straight.to_turn(_v(1, 8), _R)
	straight.to_portal(_v(2, 8), _v(0, 10), "pF2", "pt2")
	straight.to_receiver(_v(2, 10), "linkF", "rc")
	straight.cap()
	down.to_turn(_v(3, 5), _R)
	var re := b.remote_emitter(_v(7, 8), _D, "linkF", rcol, "re")
	re.to_turn(_v(7, 10), _L).to_turn(_v(6, 10), _U).to_turn(_v(6, 9), _L).to_turn(_v(4, 9), _U)
	re.to_one_way_turn(_v(4, 5), _R, "ow", true)
	re.to_gate(_v(5, 5), "gF", "gt")
	re.to_filter(_v(6, 5), fcol, "filt")
	re.to_target(_v(7, 5), fcol, "tgt")
	down.to_one_way_turn(_v(4, 5), _U, "ow", true)
	down.to_switch(_v(4, 3), "gF", "sw")
	down.to_turn(_v(4, 1), _R, false)
	down.to_filter(_v(5, 1), wcol, "filt2")
	down.to_target(_v(7, 1), wcol, "tw")
