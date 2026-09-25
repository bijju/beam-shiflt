class_name ProceduralFragmentsV3
extends RefCounted
## Fragment planner for Generator V3 progression (Difficulty System Phase 2B,
## D96). Composes a LOGICAL puzzle out of reusable fragments ("atoms") chosen
## from a per-band pool, BEFORE any cell exists:
##
##   band requirements (ProceduralDifficultyContract) -> atom recipe (core +
##   escalation extras, checked against a predicted depth/kinds/deps model) ->
##   a tree of "lines" (a beam route = source + ordered tokens) -> required-move
##   budget distributed over the routes' turn slots.
##
## ProceduralComposerV3 then realises the line tree on a board. Nothing here
## knows a coordinate. Difficulty is bought with dependency structure (more
## load-bearing mechanic nodes / kinds), never with extra plain rotations: the
## turn budget is spread over many short slots (interior "plain" turns are
## counted and capped per band).
##
## Atoms (the fragment catalog). `nodes`/`kinds`/`deps` model what
## ProceduralComplexity's ablation metrics will report for the finished board
## (depth = 1 + sum of nodes; interactions = kind pairs); `fixed` = required
## non-turn moves (a splitter/one-way/hold rotation); `min_level` = first level
## the atom may appear in. The planner uses the model only to CHOOSE recipes -
## the generator still verifies the real metrics on the built board.
##   F   Filter recolours the beam; the target needs that colour
##   P   Portal jump
##   H   Beam Receiver -> Remote Emitter hop (a new route starts elsewhere)
##   PR  Prism: white trunk splits, main continues on a turning colour channel
##   OW  One-Way reflector turn (wrong state PASSES or reflects the other way)
##   OH  One-Way that must PASS the beam (start state reflects)
##   TM  required Target mid-route (target continuation)
##   SB  Splitter whose branch reaches a SECOND required target
##   G   Gate on the route, opened by a Switch on its own emitter's route
##   SG  Gate opened by a Switch on a Splitter branch of the same trunk
##   PG  Gate opened by a Switch on a Prism channel of the same trunk
##   SH  Gate whose Switch route shares one mirror with the main route
##   SO  Gate whose Switch route shares one One-Way with the main route
##   GG  two-stage Gate: the Switch's own route passes a second Gate

const ATOMS := {
	"F": {"nodes": 1, "kinds": ["filter"], "deps": 1, "fixed": 0, "min_level": 1},
	"P": {"nodes": 1, "kinds": ["portal"], "deps": 1, "fixed": 0, "min_level": 1},
	"F2": {"nodes": 1, "kinds": ["filter"], "deps": 1, "fixed": 0, "min_level": 401},
	"SB": {"nodes": 1, "kinds": ["splitter"], "deps": 1, "fixed": 1, "min_level": 1},
	"G": {"nodes": 2, "kinds": ["switch", "gate"], "deps": 1, "fixed": 0, "min_level": 21},
	"SG": {"nodes": 3, "kinds": ["splitter", "switch", "gate"], "deps": 2, "fixed": 1, "min_level": 51},
	"PR": {"nodes": 1, "kinds": ["prism"], "deps": 1, "fixed": 0, "min_level": 51},
	"PG": {"nodes": 3, "kinds": ["prism", "switch", "gate"], "deps": 2, "fixed": 0, "min_level": 51},
	"SH": {"nodes": 2, "kinds": ["switch", "gate"], "deps": 2, "fixed": 0, "min_level": 51},
	"H": {"nodes": 2, "kinds": ["receiver", "remote"], "deps": 1, "fixed": 0, "min_level": 101},
	"OW": {"nodes": 1, "kinds": ["one_way"], "deps": 1, "fixed": 1, "min_level": 101},
	"OH": {"nodes": 0, "kinds": [], "deps": 0, "fixed": 1, "min_level": 401},
	"TM": {"nodes": 0, "kinds": [], "deps": 0, "fixed": 0, "min_level": 401},
	"SO": {"nodes": 3, "kinds": ["one_way", "switch", "gate"], "deps": 3, "fixed": 0, "min_level": 401},
	"GG": {"nodes": 4, "kinds": ["switch", "gate"], "deps": 2, "fixed": 0, "min_level": 401},
	# Fusion atoms (generator V4+, D100). `fixed` 1 = the node's own one-tap rotation. Never part of
	# IMPLEMENTED: only a Fusion recipe (FUSION_RECIPES) may place them, so V3 is unchanged.
	"FU": {"nodes": 1, "kinds": ["fusion"], "deps": 1, "fixed": 1, "min_level": 201},
	"FUF": {"nodes": 3, "kinds": ["fusion", "filter"], "deps": 3, "fixed": 1, "min_level": 401},
	"FUP": {"nodes": 2, "kinds": ["fusion", "portal"], "deps": 2, "fixed": 1, "min_level": 401},
	"FUG": {"nodes": 3, "kinds": ["fusion", "switch", "gate"], "deps": 2, "fixed": 1, "min_level": 701},
	"FUK": {"nodes": 3, "kinds": ["fusion", "switch", "gate"], "deps": 2, "fixed": 1, "min_level": 701},
	"PF": {"nodes": 2, "kinds": ["prism", "fusion"], "deps": 2, "fixed": 1, "min_level": 1301},
	"FU3": {"nodes": 1, "kinds": ["fusion"], "deps": 1, "fixed": 1, "min_level": 1601},
}

## Atoms the composer can currently realise. Everything else is skipped by the
## pools (kept in ATOMS so the catalog documents the intended design space).
const IMPLEMENTED := ["F", "F2", "P", "SB", "G", "SG", "PR", "PG", "H", "OW", "OH", "TM", "GG", "SH", "SO"]

## Fusion fragments (ProceduralDifficultyContract._FUSION_PROGRESSION decides where each may appear):
##   F1 FU   two independent primary paths -> Fusion -> composite target
##   F2 FUF  inputs made from WHITE emitters by Filters (a Filter recolours, so a filter AFTER a node
##           would erase the fused colour - the filters therefore sit on the input paths)
##   F3 FUP  one input path crosses a Portal
##   F4 FUG  Fusion -> Switch -> Gate on the main route
##   F5      Fusion -> Receiver -> Remote Emitter (FU + H)
##   F6 PF   Prism channels feed the Fusion
##   F7 FU3  RED + GREEN + BLUE -> WHITE -> Prism -> colour-specific targets
const FUSION_RECIPES := {
	"F1": ["FU"], "F2": ["FUF"], "F3": ["FUP"], "F4": ["FUG"], "F5": ["FU", "H"], "F6": ["PF"], "F7": ["FU3", "PR"],
}
const FUSION_ATOMS := ["FU", "FUF", "FUP", "FUG", "FUK", "PF", "FU3"]

## Fragment VARIANTS (Fusion Phase 3, D101) - generator-driven, never handwritten levels. Recipe-level
## variants are drawn ONCE in roll_fusion_recipe (after the fragment draw, so the yes/no + fragment
## stream is unchanged); atom-level variants (portal placement, prism supply, gated input) are drawn
## from the attempt rng inside _apply_atom and recorded in plan.params["fusion_variant"]:
##   F1  colour pair (RED+GREEN / RED+BLUE / GREEN+BLUE) - the shuffled primaries
##   F3  portal on input A (the node's own route) / input B / the fused OUTPUT route
##   F4  chain (Fusion -> Switch -> Gate) / gated input (a Switch opens a Gate on a prerequisite)
##   F5  Fusion -> Receiver -> Remote / the remote beam then crosses a Gate
##   F6  the Prism supplies both inputs / the Prism supplies one, an emitter the other
##   F7  three emitters / the second input crosses a Portal (two regions + one direct path)
const FUSION_RECIPE_VARIANTS := {
	"F4": [["FUG"], ["FUK"]],
	"F5": [["FU", "H"], ["FU", "H", "G"]],
}

const _COLORS: Array[int] = [GridTypes.BeamColor.RED, GridTypes.BeamColor.GREEN, GridTypes.BeamColor.BLUE]
const MAX_SLOT_TURNS := 3


## Returns {ok, reason, plan, atoms, predicted, moves, keep, plain_fraction}.
static func compose(level_number: int, req: Dictionary, rng: RandomNumberGenerator, layout_failures: int = 0, fusion_recipe: Array[String] = []) -> Dictionary:
	var atoms := choose_atoms(level_number, req, rng, fusion_recipe)
	if atoms.is_empty() and level_number > 8:
		return {"ok": false, "reason": "no atom recipe satisfies the band"}
	# Dense late puzzles can physically not fit the top of the move window on an 8-column
	# portrait board; every layout failure lowers the target by 2 (never below the band floor).
	var moves := maxi(int(req["min_optimal_moves"]), _draw_moves(level_number, req, rng) - 2 * layout_failures)
	var keep := int(round(float(moves) * float(req["keep_correct_fraction"])))
	if float(req["keep_correct_fraction"]) > 0.0:
		keep = maxi(keep, 1)
	var built := _build_plan(level_number, atoms, rng)
	var plan: ProceduralPlanV3 = built["plan"]
	var slots: Array = built["slots"]
	var fixed := 0
	for a in atoms:
		fixed += int(ATOMS[a]["fixed"])
	var max_slot := 4 if level_number <= 20 else MAX_SLOT_TURNS
	var min_turns := 0
	for s in slots:
		min_turns += int(s["min"])
	# Never ask a plan for more turns than its slots can hold: the mirror-only
	# routes of the first levels simply cap their own move count.
	var capacity := slots.size() * max_slot
	moves = mini(moves, capacity + fixed - keep)
	if moves < int(req["min_optimal_moves"]):
		return {"ok": false, "reason": "%d turn slots cannot hold the band's minimum of %d moves" % [slots.size(), int(req["min_optimal_moves"])]}
	# A plan with many turn slots may need more than the drawn move target (a slot needs at least
	# one turn); raise the target to the plan's minimum when the band window still allows it.
	moves = maxi(moves, mini(int(req["max_optimal_moves"]), min_turns + fixed - keep))
	var turn_budget := moves + keep - fixed
	if turn_budget < min_turns:
		return {"ok": false, "reason": "%d atoms need >= %d turns but the budget is %d" % [atoms.size(), min_turns, turn_budget]}
	var plain_cap: float = float(req["max_plain_move_fraction"])
	# "Plain" = interior turns of a slot (more than the two that touch a mechanic).
	# The already-correct mirrors are drawn from all mirrors, so only the required
	# share of the interior turns can ever be a plain MOVE.
	var required_share := float(moves) / float(maxi(moves + keep - fixed, 1))
	var distributed := _distribute(slots, turn_budget, moves, plain_cap, required_share, max_slot, rng)
	if not distributed:
		return {"ok": false, "reason": "turn budget %d cannot be spread within the plain-move cap" % turn_budget}
	var plain := 0
	for s in slots:
		plain += maxi(0, int(s["n"]) - 2)
	plan.archetype = "+".join(atoms) if not atoms.is_empty() else "route"
	plan.title = "V3 L%d [%s]" % [level_number, plan.archetype]
	plan.params["keep_correct"] = keep
	# Hop-length bias: sparse early boards spread out, dense late boards pack tight.
	plan.params["alpha"] = 0.3 if level_number <= 400 else (0.6 if level_number <= 1000 else 1.0)
	return {
		"ok": true, "reason": "", "plan": plan, "atoms": atoms, "predicted": predict(atoms),
		"tile_estimate": estimate_tiles(atoms, turn_budget), "moves": moves, "keep": keep, "plain_fraction": minf(1.0, float(plain) * required_share / float(maxi(moves, 1))),
	}


static func predict(atoms: Array) -> Dictionary:
	var nodes := 0
	var deps := 0
	var kinds := {}
	for a in atoms:
		nodes += int(ATOMS[a]["nodes"])
		deps += int(ATOMS[a]["deps"])
		for k in ATOMS[a]["kinds"]:
			kinds[k] = true
	# With a mid-route target the FIRST filter only serves that target: the final target's
	# colour is set by the second one, so the first is not on the final causal chain.
	if atoms.has("TM") and atoms.has("F2"):
		nodes -= 1
	return {"depth": 1 + nodes, "deps": deps, "kinds": kinds.size(), "kind_set": kinds.keys()}


# --- Recipe selection ----------------------------------------------------------

static func _available(level_number: int) -> Array[String]:
	var out: Array[String] = []
	for a in IMPLEMENTED:
		if level_number >= int(ATOMS[a]["min_level"]):
			out.append(a)
	return out


## Core recipes per band (the user's Phase 2B archetype pools). Escalation
## extras are then appended until the predicted depth/kinds/deps meet the band.
static func _cores_for(level_number: int) -> Array:
	if level_number <= 8:
		return [[], [], ["F"]]
	if level_number <= 20:
		return [[], ["F"], ["P"], ["SB"]]
	if level_number <= 50:
		return [["F", "P"], ["G"], ["SB", "F"], ["SB", "P"], ["P", "G"]]
	if level_number <= 100:
		return [["G", "F"], ["SG"], ["PR", "F", "P"], ["SB", "F", "P"], ["SH", "F"], ["PG"]]
	if level_number <= 200:
		return [["G", "F"], ["SG"], ["PG"], ["PR", "F", "P"], ["PR", "H"], ["H", "F"], ["OW", "F", "P"], ["OW", "G"], ["H", "P"], ["SH", "F"]]
	if level_number <= 400:
		return [["SG", "F"], ["SH", "F", "P"], ["PR", "H", "F"], ["OW", "G", "F"], ["H", "P", "F"], ["PG", "F"], ["SB", "G", "F"], ["GG", "F"]]
	if level_number <= 700:
		return [["SG", "F"], ["PR", "H", "F"], ["SO", "F"], ["OW", "H", "F"], ["PG", "F"], ["H", "G", "F"], ["GG", "F", "P"], ["OH", "SG", "F"]]
	if level_number <= 1000:
		return [["SG", "H", "F"], ["PG", "H", "F"], ["SO", "H", "F"], ["GG", "H", "F"], ["H", "G", "F", "P"], ["PR", "SG", "F"], ["OW", "SG", "F"]]
	return [["SG", "H", "F"], ["PG", "H", "F"], ["SO", "H", "F"], ["GG", "H", "F"], ["PR", "SG", "H", "F"], ["OW", "GG", "F"], ["SH", "H", "H", "F"]]


static func choose_atoms(level_number: int, req: Dictionary, rng: RandomNumberGenerator, fusion_recipe: Array[String] = []) -> Array[String]:
	var avail := _available(level_number)
	# Fusion (generator V4+): `fusion_recipe` is the level's ONE Fusion roll (see roll_fusion_recipe), passed
	# in by the progression generator; [] = an ordinary recipe. No rng is consumed here for it, so V3 draws
	# (which always pass []) are untouched.
	var fusion_core: Array[String] = fusion_recipe
	var min_depth: int = int(req["min_dependency_depth"])
	# Depth/dependency CEILINGS bind the early game only (Levels <= 200); above that they are
	# soft targets (the metric also counts convergence/shared resources the model cannot pre-count).
	var ceilings := level_number <= 200
	var max_depth: int = int(req["max_dependency_depth"]) if ceilings else ProceduralDifficultyContract.UNBOUNDED
	var min_deps: int = int(req["min_meaningful_dependencies"])
	var max_deps: int = int(req["max_meaningful_dependencies"]) if ceilings else ProceduralDifficultyContract.UNBOUNDED
	var min_kinds: int = int(req["min_distinct_mechanics"])

	# Start from a core recipe whose predicted cost already respects the band's ceilings.
	var usable: Array = []
	if fusion_core.is_empty():
		for core in _cores_for(level_number):
			var filtered: Array[String] = []
			for a in core:
				if avail.has(a):
					filtered.append(a)
			if _within_caps(predict(filtered), max_depth, max_deps):
				usable.append(filtered)
		if usable.is_empty():
			return []
	var atoms: Array[String] = []
	if fusion_core.is_empty():
		atoms.assign(usable[rng.randi_range(0, usable.size() - 1)])
	else:
		atoms.assign(fusion_core)
		if not _within_caps(predict(atoms), max_depth, max_deps):
			return []

	for _i in range(12):
		var p := predict(atoms)
		if p["depth"] >= min_depth and p["kinds"] >= min_kinds and p["deps"] >= min_deps:
			break
		# Escalate: prefer atoms that add new kinds; when the dependency ceiling
		# binds, prefer two-node atoms (more depth per dependency).
		var options: Array[String] = []
		var weights: Array[float] = []
		for a in avail:
			if a == "TM" or a == "OH" or a == "F2" or not _can_add(atoms, a):
				continue
			# A Filter after a Fusion node would recolour (erase) the fused colour, and a second Prism/mid-route
			# target has no WHITE/primary beam to work with: Fusion recipes never escalate with them.
			if not fusion_core.is_empty() and (a == "F" or a == "PR" or a == "PG"):
				continue
			var atom: Dictionary = ATOMS[a]
			var grows := 0
			for k in atom["kinds"]:
				if not p["kind_set"].has(k):
					grows += 1
			if grows == 0 and p["kinds"] < min_kinds:
				continue
			if max_deps != ProceduralDifficultyContract.UNBOUNDED and p["deps"] + int(atom["deps"]) > max_deps:
				continue
			if max_depth != ProceduralDifficultyContract.UNBOUNDED and p["depth"] + int(atom["nodes"]) > max_depth:
				continue
			var w := 1.0 + 2.0 * float(grows)
			if p["depth"] < min_depth:
				w += float(atom["nodes"]) - float(atom["deps"])
			options.append(a)
			weights.append(maxf(w, 0.2))
		if options.is_empty():
			return []
		atoms.append(options[_weighted(weights, rng)])

	# Optional advanced patterns (only once the band allows their cost).
	if fusion_core.is_empty() and level_number >= 401 and avail.has("TM") and atoms.has("F") and rng.randf() < (0.5 if level_number >= 1001 else 0.3):
		var trial: Array[String] = atoms.duplicate()
		trial.append("TM")
		trial.append("F2")
		if _within_caps(predict(trial), max_depth, max_deps):
			atoms = trial
	if fusion_core.is_empty() and level_number >= 401 and avail.has("OH") and rng.randf() < 0.25:
		atoms.append("OH")

	var final := predict(atoms)
	if final["depth"] < min_depth or final["kinds"] < min_kinds or final["deps"] < min_deps:
		return []
	if not _within_caps(final, max_depth, max_deps):
		return []
	# Prisms must see a WHITE beam, so they lead; the first filter precedes a
	# mid-route target, the second follows it. Keyed sort (index tie-break) so
	# the order is fully deterministic.
	var has_tm := atoms.has("TM")
	var has_fu3 := atoms.has("FU3")
	var keyed: Array = []
	for i in range(atoms.size()):
		keyed.append([_order(atoms[i], has_tm, has_fu3) * 100 + i, atoms[i]])
	keyed.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	var sorted: Array[String] = []
	for k in keyed:
		sorted.append(k[1])
	return sorted


## The Fusion recipe this level rolls ONCE (or [] = an ordinary V3-style recipe). Deterministic: one draw for
## the yes/no and one for the fragment, both from the level's own dedicated rng (never re-rolled per attempt, so a
## fragment that is hard to place does not silently lower the band's Fusion frequency).
static func roll_fusion_recipe(level_number: int, rng: RandomNumberGenerator) -> Array[String]:
	var policy := ProceduralDifficultyContract.fusion_policy(level_number)
	var fragments: Array = policy["fragments"]
	var out: Array[String] = []
	if fragments.is_empty() or rng.randf() >= float(policy["probability"]):
		return out
	var frag: String = fragments[rng.randi_range(0, fragments.size() - 1)]
	if FUSION_RECIPE_VARIANTS.has(frag):
		var options: Array = FUSION_RECIPE_VARIANTS[frag]
		out.assign(options[rng.randi_range(0, options.size() - 1)])
	else:
		out.assign(FUSION_RECIPES[frag])
	return out


## The fragment id (F1..F7) a finished atom list realises, or "" (report/QA only).
static func fusion_fragment_of(atoms: Array) -> String:
	if atoms.has("PF"):
		return "F6"
	if atoms.has("FU3"):
		return "F7"
	if atoms.has("FUF"):
		return "F2"
	if atoms.has("FUP"):
		return "F3"
	if atoms.has("FUG") or atoms.has("FUK"):
		return "F4"
	if atoms.has("FU") and atoms.has("H"):
		return "F5"
	if atoms.has("FU"):
		return "F1"
	return ""


## At most one Prism (it needs a WHITE beam), one Filter (a second is only
## load-bearing around a mid-route target), and duplicates of everything else
## are fine.
static func _can_add(atoms: Array, atom: String) -> bool:
	# Fusion boards: every H needs a remote colour no other beam uses, and the fusion inputs already use
	# 2 (or 3) of the 3 primaries - so a Fusion recipe can afford only (3 - inputs) hops; a further one
	# would fall back to a WHITE remote (a colour bypass).
	if atom == "H" and _has_fusion(atoms):
		var hops := 0
		for a in atoms:
			if a == "H":
				hops += 1
		return hops < 3 - (3 if atoms.has("FU3") else 2)
	if atom == "PR" or atom == "PG" or atom == "PF":
		return not (atoms.has("PR") or atoms.has("PG") or atoms.has("PF"))
	if atom == "F":
		return not atoms.has("F")
	return true


static func _within_caps(p: Dictionary, max_depth: int, max_deps: int) -> bool:
	if max_depth != ProceduralDifficultyContract.UNBOUNDED and p["depth"] > max_depth:
		return false
	if max_deps != ProceduralDifficultyContract.UNBOUNDED and p["deps"] > max_deps:
		return false
	return true


## Placement order along the main chain (x10). A prism must see a WHITE beam so it
## leads; with a mid-route target the first filter sits right before it (same
## line, so its colour is what the target asks for) and the second follows it;
## the splitter branch to a second target comes last so it inherits the colour.
static func _order(atom: String, has_tm: bool, has_fu3: bool = false) -> int:
	match atom:
		"PR", "PG":
			# A Prism after a three-colour Fusion sees the node's WHITE output, so it follows the node.
			return 5 if has_fu3 else 0
		"PF":
			return 0 # the Prism inside PF must see the root WHITE beam
		"FU", "FUF", "FUP", "FUK", "FU3":
			return 1 # the node sits on the root route: everything else acts on its output
		"FUG":
			return 20
		"SG", "SH", "SO":
			return 10
		"G", "GG", "OW", "OH", "H", "P":
			return 20
		"F":
			return 29 if has_tm else 40
		"TM":
			return 30
		"F2":
			return 40
		"SB":
			return 50
	return 30


static func _weighted(weights: Array[float], rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.randf() * total
	for i in range(weights.size()):
		r -= weights[i]
		if r <= 0.0:
			return i
	return weights.size() - 1


# --- Line tree -------------------------------------------------------------------

class _B extends RefCounted:
	var plan := ProceduralPlanV3.new()
	var slots: Array = []
	var seq := 0
	var rng: RandomNumberGenerator
	var root: Dictionary
	var cur: Dictionary
	var tail: Array = []

	func nid(prefix: String) -> String:
		seq += 1
		return "%s%d" % [prefix, seq]

	func line(kind: String, color: int = GridTypes.BeamColor.WHITE) -> Dictionary:
		return {"src": {"kind": kind, "color": color}, "tokens": []}

	## A turn slot: n >= min rotatable mirrors before the next element.
	func slot(into: Dictionary, min_n: int = 1) -> Dictionary:
		var s := {"t": "turn", "n": min_n, "min": min_n, "kind": "mirror"}
		into["tokens"].append(s)
		slots.append(s)
		return s

	func tok(into: Dictionary, t: Dictionary) -> Dictionary:
		into["tokens"].append(t)
		return t

	func stage(id: String, role: String, lb: bool, color: int = -1) -> void:
		plan.add_stage(id, role, lb, 0, color)


static func _color(rng: RandomNumberGenerator) -> int:
	return _COLORS[rng.randi_range(0, 2)]


static func _switch_line(b: _B, gid: String, color_of_emitter: int, kind: String = "emitter") -> Dictionary:
	var f := b.line(kind, color_of_emitter)
	b.slot(f)
	var sid := b.nid("sw")
	b.stage(sid, "switch", true)
	b.tok(f, {"t": "switch", "gate": gid, "id": sid})
	return f


static func _build_plan(level_number: int, atoms: Array, rng: RandomNumberGenerator) -> Dictionary:
	var b := _B.new()
	b.rng = rng
	b.root = b.line("emitter", GridTypes.BeamColor.WHITE)
	b.cur = b.root
	for a in atoms:
		_apply_atom(b, a, atoms, rng)
	# Tail gates (the gate atoms whose feeder already exists upstream).
	for t in b.tail:
		b.slot(b.cur)
		b.tok(b.cur, t)
	b.slot(b.cur)
	var tid := b.nid("tg")
	b.tok(b.cur, {"t": "target", "id": tid, "mid": false})
	b.plan.lines = [b.root]
	return {"plan": b.plan, "slots": b.slots}


static func _apply_atom(b: _B, atom: String, atoms: Array, rng: RandomNumberGenerator) -> void:
	var cur: Dictionary = b.cur
	match atom:
		"F", "F2":
			b.slot(cur)
			var id := b.nid("f")
			b.stage(id, "filter", true)
			b.tok(cur, {"t": "filter", "id": id, "color": _color(rng)})
		"P":
			b.slot(cur)
			var id := b.nid("p")
			b.stage(id, "portal", true)
			b.tok(cur, {"t": "portal", "id": id})
		"OW":
			b.slot(cur)
			var id := b.nid("ow")
			b.stage(id, "one_way", true)
			b.tok(cur, {"t": "turn", "n": 1, "min": 1, "kind": "one_way", "fixed": true, "attach": true, "id": id})
		"OH":
			b.slot(cur)
			var id := b.nid("oh")
			b.stage(id, "one_way", false)
			b.tok(cur, {"t": "hold", "id": id})
		"TM":
			b.slot(cur)
			b.tok(cur, {"t": "target", "id": b.nid("tm"), "mid": true})
		"H":
			b.slot(cur)
			var rid := b.nid("rc")
			var eid := b.nid("re")
			var link := b.nid("link")
			b.stage(rid, "receiver", true)
			b.stage(eid, "remote", true)
			# A remote that a Prism atom still has to feed must emit WHITE.
			var later_prism := atoms.has("PR") or atoms.has("PG") or atoms.has("F2")
			var color := GridTypes.BeamColor.WHITE if later_prism or rng.randi_range(0, 1) == 0 else _color(rng)
			if _has_fusion(atoms):
				color = _color(rng) # explicit remote colour: a WHITE remote would accept any target colour
			var nxt := b.line("remote", color)
			b.tok(cur, {"t": "hop", "link": link, "rid": rid, "eid": eid, "color": color, "next": nxt})
			b.cur = nxt
		"SB":
			b.slot(cur)
			var id := b.nid("sp")
			b.stage(id, "splitter", true)
			var branch := b.line("branch")
			b.slot(branch)
			b.tok(branch, {"t": "target", "id": b.nid("tb"), "mid": false})
			b.tok(cur, {"t": "splitter", "id": id, "branch": branch})
		"G":
			b.slot(cur)
			var gid := b.nid("g")
			b.tok(cur, {"t": "gate", "gate": gid, "id": b.nid("gt"), "feeder": _switch_line(b, gid, GridTypes.BeamColor.WHITE)})
		"SG":
			b.slot(cur)
			var id := b.nid("sp")
			b.stage(id, "splitter", true)
			var gid := b.nid("g")
			var branch := _switch_line(b, gid, GridTypes.BeamColor.WHITE, "branch")
			b.tok(cur, {"t": "splitter", "id": id, "branch": branch})
			b.tail.append({"t": "gate", "gate": gid, "id": b.nid("gt")})
		"PR", "PG":
			b.slot(cur)
			var id := b.nid("pr")
			b.stage(id, "prism", true)
			var nxt := b.line("channel", GridTypes.BeamColor.WHITE)
			var token := {"t": "prism", "id": id, "main": nxt, "feeders": []}
			if atom == "PG":
				var gid := b.nid("g")
				token["feeders"].append(_switch_line(b, gid, GridTypes.BeamColor.WHITE, "channel"))
				b.tail.append({"t": "gate", "gate": gid, "id": b.nid("gt")})
			b.tok(cur, token)
			b.cur = nxt
		"GG":
			b.slot(cur)
			var g1 := b.nid("g")
			var g2 := b.nid("g")
			var f1 := b.line("emitter", GridTypes.BeamColor.WHITE)
			b.slot(f1)
			f1["tokens"].append({"t": "gate", "gate": g2, "id": b.nid("gt"), "feeder": _switch_line(b, g2, GridTypes.BeamColor.WHITE)})
			b.slot(f1)
			var sid := b.nid("sw")
			b.stage(sid, "switch", true)
			f1["tokens"].append({"t": "switch", "gate": g1, "id": sid})
			b.tok(cur, {"t": "gate", "gate": g1, "id": b.nid("gt"), "feeder": f1})
		"SH":
			# The turn slot right before the gate ends on the SHARED mirror; the
			# Switch route later joins that same mirror through its other channel.
			var s := b.slot(cur)
			var share := b.nid("sh")
			s["share"] = share
			var gid := b.nid("g")
			var f := b.line("emitter", GridTypes.BeamColor.WHITE)
			b.slot(f)
			f["tokens"].append({"t": "join", "share": share, "kind": "mirror"})
			b.slot(f, 0)
			var sid := b.nid("sw")
			b.stage(sid, "switch", true)
			f["tokens"].append({"t": "switch", "gate": gid, "id": sid})
			b.tok(cur, {"t": "gate", "gate": gid, "id": b.nid("gt"), "feeder": f})
		"SO":
			var s := b.slot(cur)
			var share := b.nid("so")
			s["share"] = share
			s["share_kind"] = "one_way"
			var sid_ow := b.nid("ow")
			b.stage(sid_ow, "one_way", true)
			s["share_id"] = sid_ow
			var gid := b.nid("g")
			var f := b.line("emitter", GridTypes.BeamColor.WHITE)
			b.slot(f)
			f["tokens"].append({"t": "join", "share": share, "kind": "one_way"})
			b.slot(f, 0)
			var sid := b.nid("sw")
			b.stage(sid, "switch", true)
			f["tokens"].append({"t": "switch", "gate": gid, "id": sid})
			b.tok(cur, {"t": "gate", "gate": gid, "id": b.nid("gt"), "feeder": f})
		"FU", "FUF", "FUP", "FUK", "FU3":
			# Fusion node on the root route (sorted first, so `cur` is the root emitter line).
			var cols := _shuffled_primaries(rng)
			var variant := "plain"
			match atom:
				"FUF":
					variant = "filter"
				"FUP": # F3: the portal sits on input B, on the node's own route (input A) or on the fused output
					variant = ["portal", "portal_a", "portal_out"][rng.randi_range(0, 2)]
				"FUK": # F4: a Switch opens a Gate on the second prerequisite path
					variant = "gate"
				"FU3": # F7: three emitters, or the second input crossing a Portal
					variant = "portal" if rng.randi_range(0, 1) == 1 else "plain"
			if variant != "filter":
				cur["src"]["color"] = cols[0]
			b.plan.params["fusion_variant"] = variant
			var built := _fusion_on(b, cur, variant, 3 if atom == "FU3" else 2, cols, rng)
			b.cur = built["out"]
		"FUG":
			# Gate on the main route; its feeder is a route that ends in a Fusion node whose output
			# reaches the Switch (prerequisite paths -> Fusion -> Switch -> Gate).
			b.slot(cur)
			var gid := b.nid("g")
			var cols := _shuffled_primaries(rng)
			b.plan.params["fusion_variant"] = "chain"
			var line_a := b.line("emitter", cols[0])
			var built := _fusion_on(b, line_a, "plain", 2, cols, rng)
			var out: Dictionary = built["out"]
			b.slot(out)
			var sid := b.nid("sw")
			b.stage(sid, "switch", true)
			b.tok(out, {"t": "switch", "gate": gid, "id": sid})
			b.tok(cur, {"t": "gate", "gate": gid, "id": b.nid("gt"), "feeder": line_a})
		"PF":
			# Prism whose main channel and one more channel are the Fusion's two inputs.
			b.slot(cur)
			var pid := b.nid("pr")
			b.stage(pid, "prism", true)
			var line_a := b.line("channel", GridTypes.BeamColor.WHITE)
			if rng.randi_range(0, 1) == 0:
				b.plan.params["fusion_variant"] = "prism_both"
				var line_b := b.line("channel", GridTypes.BeamColor.WHITE)
				var built := _fusion_on(b, line_a, "prism", 2, [], rng)
				b.slot(line_b)
				b.tok(line_b, {"t": "fjoin", "fid": built["fid"]})
				b.tok(cur, {"t": "prism", "id": pid, "main": line_a, "feeders": [line_b]})
				b.cur = built["out"]
			else:
				# The Prism's straight (RED) channel is ONE input; a separate GREEN or BLUE emitter is the other.
				b.plan.params["fusion_variant"] = "prism_one"
				var other: int = _COLORS[rng.randi_range(1, 2)]
				var built := _fusion_on(b, line_a, "plain", 2, [GridTypes.BeamColor.RED, other], rng)
				b.tok(cur, {"t": "prism", "id": pid, "main": line_a, "feeders": []})
				b.cur = built["out"]


## The three primaries in a level-rng-shuffled order (Array.shuffle() would use the global rng).
static func _has_fusion(atoms: Array) -> bool:
	for a in FUSION_ATOMS:
		if atoms.has(a):
			return true
	return false


static func _shuffled_primaries(rng: RandomNumberGenerator) -> Array:
	var a: Array = _COLORS.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
	return a


## Builds one Fusion node on `line_a` (its route ends AT the node) and returns {out: the fused
## output line, fid}. `variant`: "plain" (primary emitters), "filter" (WHITE emitters + a Filter on
## every input path), "portal" (the first extra input crosses a Portal), "portal_a" (the node's own
## route crosses a Portal), "portal_out" (the FUSED output route crosses a Portal), "gate" (the first
## extra input crosses a Gate opened by an independent Switch), "prism" (the extra inputs are prism
## channels the caller wires up itself - no emitter feeders are created here).
static func _fusion_on(b: _B, line_a: Dictionary, variant: String, n_in: int, cols: Array, rng: RandomNumberGenerator) -> Dictionary:
	var fid := b.nid("fu")
	b.stage(fid, "fusion", true)
	var out := b.line("fusion_out")
	var feeders: Array = []
	b.slot(line_a)
	if variant == "filter":
		var fa := b.nid("f")
		b.stage(fa, "filter", true)
		b.tok(line_a, {"t": "filter", "id": fa, "color": _color(rng)})
		b.slot(line_a)
	elif variant == "portal_a":
		var pa := b.nid("p")
		b.stage(pa, "portal", true)
		b.tok(line_a, {"t": "portal", "id": pa})
		b.slot(line_a)
	if variant != "prism":
		for i in range(1, n_in):
			var f := b.line("emitter", GridTypes.BeamColor.WHITE if variant == "filter" else cols[i])
			b.slot(f)
			if variant == "filter":
				var fb := b.nid("f")
				b.stage(fb, "filter", true)
				b.tok(f, {"t": "filter", "id": fb, "color": _color(rng)})
				b.slot(f)
			elif variant == "portal" and i == 1:
				var pid := b.nid("p")
				b.stage(pid, "portal", true)
				b.tok(f, {"t": "portal", "id": pid})
				b.slot(f)
			elif variant == "gate" and i == 1:
				var gid := b.nid("g")
				b.tok(f, {"t": "gate", "gate": gid, "id": b.nid("gt"), "feeder": _switch_line(b, gid, GridTypes.BeamColor.WHITE)})
				b.slot(f)
			b.tok(f, {"t": "fjoin", "fid": fid})
			feeders.append(f)
	b.tok(line_a, {"t": "fusion", "fid": fid, "n_in": n_in, "feeders": feeders, "out": out})
	if variant == "portal_out":
		b.slot(out)
		var po := b.nid("p")
		b.stage(po, "portal", true)
		b.tok(out, {"t": "portal", "id": po})
	return {"out": out, "fid": fid}


## Spreads `turn_budget` turns over the slots (each at least its minimum, at
## most `max_slot`), filling short slots first so interior "plain" turns stay
## rare, and checks the plain-move cap. Returns false when impossible.
static func _distribute(slots: Array, turn_budget: int, moves: int, plain_cap: float, required_share: float, max_slot: int, rng: RandomNumberGenerator) -> bool:
	var total := 0
	for s in slots:
		s["n"] = int(s["min"])
		total += int(s["n"])
	var rest := turn_budget - total
	var level_cap := 2
	while rest > 0:
		var open: Array = []
		for s in slots:
			if int(s["n"]) < level_cap:
				open.append(s)
		if open.is_empty():
			if level_cap >= max_slot:
				return false
			level_cap += 1
			continue
		var pick: Dictionary = open[rng.randi_range(0, open.size() - 1)]
		pick["n"] = int(pick["n"]) + 1
		rest -= 1
	var plain := 0
	for s in slots:
		plain += maxi(0, int(s["n"]) - 2)
	return float(plain) * required_share / float(maxi(moves, 1)) <= plain_cap + 0.0001


## The move target inside the band window. Dense late boards fit the low end far
## more reliably (a 26-move, 10-unit puzzle needs ~60% of an 8x11 board), so from
## Level 1301 the draw is skewed toward the lower half; earlier bands are uniform.
static func _draw_moves(level_number: int, req: Dictionary, rng: RandomNumberGenerator) -> int:
	var lo: int = req["min_optimal_moves"]
	var hi: int = req["max_optimal_moves"]
	if level_number <= 20:
		# Foundation ramps from the floor to the ceiling (Level 1 = 3 moves, Level 20 = 5)
		# so the very first puzzles are as gentle as the band allows.
		var ramp := float(level_number - 1) / 19.0
		return clampi(lo + int(round(float(hi - lo) * ramp)) - rng.randi_range(0, 1), lo, hi)
	if level_number < 1301:
		return rng.randi_range(lo, hi)
	var r := rng.randf()
	return lo + int(round(float(hi - lo) * r * r))


## Tile footprint of each atom beyond its turn mirrors (special tiles + the
## blockers/emitters the composer adds around them) - the layout density model.
const TILE_COST := {
	"F": 1, "F2": 1, "P": 2, "SB": 3, "TM": 1, "G": 5, "SG": 5, "PR": 3, "PG": 5,
	"H": 4, "OW": 1, "OH": 1, "SH": 5, "SO": 5, "GG": 10,
	"FU": 4, "FUF": 6, "FUP": 6, "FUG": 7, "FUK": 7, "PF": 5, "FU3": 7,
}
const BASE_TILE_COST := 4 # root emitter + blocker behind it + final target + end cap


## Estimated tiles on the finished board (turn mirrors incl. already-correct ones +
## special tiles + caps); reported next to the real tile count so the model can be
## audited. (Hardening blockers are added on top of this estimate.)
static func estimate_tiles(atoms: Array, turns: int) -> int:
	var n := BASE_TILE_COST + turns
	for a in atoms:
		n += int(TILE_COST[a])
	return n
