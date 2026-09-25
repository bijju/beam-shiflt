class_name ProceduralPlannerV3
extends RefCounted
## Logical planner for Generator V3 (D94): decides WHICH mechanics carry the
## puzzle and how they depend on each other BEFORE any cell is chosen. Every
## archetype is a reusable dependency structure, not a level; the seeded rng
## only varies incidental choices (colors, mirror-image flip, how many
## rotatables begin already correct). Physical placement is
## ProceduralLayoutV3's job.

const ARCHETYPES: Array[String] = [
	"switch_gate_shared",     # A: Switch -> Gate -> another route (+ shared reflector, color filter)
	"prism_color_portal",     # B: Prism + color reasoning + Filter + Portal
	"portal_receiver_remote", # C: Portal -> Receiver -> Remote Emitter -> Filter -> Target
	"shared_one_way",         # D: one One-Way Reflector shared by two routes + Switch/Gate
	"splitter_convergence",   # E: two branches that must BOTH hold for the final route
	"mixed_chain",            # F: Prism -> {Switch->Gate, Portal->Receiver->Remote->One-Way->Filter} -> Target
]

const _COLORS: Array[int] = [GridTypes.BeamColor.RED, GridTypes.BeamColor.GREEN, GridTypes.BeamColor.BLUE]


static func archetype_for_index(index: int) -> String:
	return ARCHETYPES[posmod(index - 1, ARCHETYPES.size())]


static func plan(archetype: String, rng: RandomNumberGenerator) -> ProceduralPlanV3:
	var p := ProceduralPlanV3.new()
	p.archetype = archetype
	p.params["flip_v"] = rng.randi_range(0, 1) == 1
	p.params["keep_correct"] = rng.randi_range(0, 2)
	match archetype:
		"switch_gate_shared":
			_plan_a(p, rng)
		"prism_color_portal":
			_plan_b(p, rng)
		"portal_receiver_remote":
			_plan_c(p, rng)
		"shared_one_way":
			_plan_d(p, rng)
		"splitter_convergence":
			_plan_e(p, rng)
		_:
			_plan_f(p, rng)
	return p


static func _two_colors(rng: RandomNumberGenerator) -> Array[int]:
	var a: int = _COLORS[rng.randi_range(0, 2)]
	var b := a
	while b == a:
		b = _COLORS[rng.randi_range(0, 2)]
	return [a, b]


static func third_color(a: int, b: int) -> int:
	for c in _COLORS:
		if c != a and c != b:
			return c
	return GridTypes.BeamColor.WHITE


static func _plan_a(p: ProceduralPlanV3, rng: RandomNumberGenerator) -> void:
	p.title = "Prototype A - Switch -> Gate -> second route"
	var c: int = _COLORS[rng.randi_range(0, 2)]
	p.params["filter_color"] = c
	p.add_stage("r1", "route", false, 4)
	p.add_stage("share", "shared_mirror", false, 1)
	p.add_stage("sw", "switch", true)
	p.add_stage("gt", "gate")
	p.add_stage("r2", "route", false, 5)
	p.add_stage("filt", "filter", true, 0, c)
	p.add_stage("tgt", "target", false, 0, c)
	p.add_edge("r1", "share", "feeds")
	p.add_edge("r2", "share", "shares")
	p.add_edge("share", "sw", "feeds")
	p.add_edge("sw", "gt", "enables")
	p.add_edge("gt", "filt", "feeds")
	p.add_edge("filt", "tgt", "feeds")
	p.add_edge("ow", "tw", "feeds")
	p.add_edge("tw", "tgt", "converges")
	p.reasoning = "One mirror serves both beams. Beam 1 must be routed through it to hit the Switch, which opens the Gate on beam 2's exit route; beam 2 must also pass the Filter so the target's color matches. Fixing the shared mirror for one beam without checking the other breaks the chain."


static func _plan_b(p: ProceduralPlanV3, rng: RandomNumberGenerator) -> void:
	p.title = "Prototype B - Prism color branches, Filter, Portal"
	p.add_stage("trunk", "trunk", false, 4)
	p.add_stage("pr", "prism", true)
	p.add_stage("red", "route", false, 2)
	p.add_stage("pt", "portal", true)
	p.add_stage("filt", "filter", true)
	p.add_stage("blue", "route", false, 3)
	p.add_stage("t1", "target", false, 0, GridTypes.BeamColor.RED)
	p.add_stage("t2", "target")
	p.add_edge("trunk", "pr", "feeds")
	p.add_edge("pr", "red", "feeds")
	p.add_edge("pr", "pt", "feeds")
	p.add_edge("pt", "filt", "feeds")
	p.add_edge("red", "t1", "converges")
	p.add_edge("filt", "t2", "converges")
	p.reasoning = "The white beam splits at the Prism. The straight (red) channel needs its own route to a red target; the turning channel must cross the Portal (the jump moves the beam far from where it entered), then pass the Filter, which recolors it to the second target's color. Both channels come from the same trunk, so every trunk mirror matters to both targets."


static func _plan_c(p: ProceduralPlanV3, rng: RandomNumberGenerator) -> void:
	p.title = "Prototype C - Portal -> Receiver -> Remote Emitter"
	var cs := _two_colors(rng)
	p.params["remote_color"] = cs[0]
	p.params["filter_color"] = cs[1]
	p.add_stage("e1", "route", false, 5)
	p.add_stage("pt", "portal", true)
	p.add_stage("post", "route", false, 2)
	p.add_stage("rc", "receiver", true)
	p.add_stage("re", "remote", true, 0, cs[0])
	p.add_stage("filt", "filter", true, 0, cs[1])
	p.add_stage("r2", "route", false, 2)
	p.add_stage("tgt", "target", false, 0, cs[1])
	p.add_stage("tw", "target", false, 0, p.params.get("wrong_color", -1))
	p.add_edge("e1", "pt", "feeds")
	p.add_edge("pt", "rc", "feeds")
	p.add_edge("rc", "re", "enables")
	p.add_edge("re", "filt", "feeds")
	p.add_edge("filt", "tgt", "feeds")
	p.reasoning = "The only visible emitter cannot reach the target. Its beam must be steered into the Portal; the exit is elsewhere and must be steered onto the Receiver, which powers the Remote Emitter. The remote beam then needs its own route and passes a Filter to match the target color."


static func _plan_d(p: ProceduralPlanV3, rng: RandomNumberGenerator) -> void:
	p.title = "Prototype D - Shared One-Way: pass vs reflect (Phase 2A.1)"
	var cs := _two_colors(rng)
	p.params["color_a"] = cs[0]
	p.params["color_b"] = cs[1]
	p.params["filter_color"] = third_color(cs[0], cs[1])
	p.params["keep_correct"] = 0 # start states are set explicitly by the layout
	p.add_stage("ra", "route", false, 4, cs[0])
	p.add_stage("ow", "one_way", true, 1)
	p.add_stage("sw", "switch", true)
	p.add_stage("pt", "portal", true)
	p.add_stage("gt", "gate")
	p.add_stage("hold", "one_way", false, 1)
	p.add_stage("rb", "route", false, 2, cs[1])
	p.add_stage("filt", "filter", true, 0, p.params["filter_color"])
	p.add_stage("ta", "target", false, 0, cs[0])
	p.add_stage("tb", "target", false, 0, p.params["filter_color"])
	p.add_edge("ra", "ow", "feeds")
	p.add_edge("rb", "ow", "shares")
	p.add_edge("ow", "sw", "feeds")
	p.add_edge("sw", "gt", "enables")
	p.add_edge("gt", "filt", "feeds")
	p.add_edge("filt", "pt", "feeds")
	p.add_edge("pt", "tb", "feeds")
	p.add_edge("ow", "hold", "feeds")
	p.add_edge("hold", "ta", "feeds")
	p.add_edge("ta", "tb", "converges")
	p.reasoning = "Beam B already reaches the shared One-Way at the start and PASSES straight through it, lighting the Switch, so the Gate looks open and the board looks half-done. But that same orientation sends beam A away. Only the other orientation reflects B toward the Gate and A up to the Switch - which closes the Gate until A actually arrives. A must then PASS a second One-Way to reach its target, so 'rotate until it reflects' is wrong there. The locally tempting state (keep B lighting the Switch) conflicts with the global one (both beams must use the shared tile)."


static func _plan_e(p: ProceduralPlanV3, rng: RandomNumberGenerator) -> void:
	p.title = "Prototype E - Converging chains, colour fork (Phase 2A.1)"
	var cs := _two_colors(rng)
	p.params["remote_color"] = cs[0]
	p.params["filter_color"] = cs[1]
	p.params["wrong_color"] = third_color(cs[0], cs[1])
	p.params["keep_correct"] = 0
	p.add_stage("trunk", "trunk", false, 4)
	p.add_stage("sp", "splitter", true, 1)
	p.add_stage("ba", "route", false, 2)
	p.add_stage("sw", "switch", true)
	p.add_stage("gt", "gate")
	p.add_stage("bb", "route", false, 2)
	p.add_stage("pt", "portal", true)
	p.add_stage("rc", "receiver", true)
	p.add_stage("re", "remote", true, 0, cs[0])
	p.add_stage("fork", "route", false, 1)
	p.add_stage("filt", "filter", true, 0, cs[1])
	p.add_stage("tgt", "target", false, 0, cs[1])
	p.add_edge("trunk", "sp", "feeds")
	p.add_edge("sp", "ba", "feeds")
	p.add_edge("sp", "bb", "feeds")
	p.add_edge("ba", "sw", "feeds")
	p.add_edge("bb", "pt", "feeds")
	p.add_edge("pt", "rc", "feeds")
	p.add_edge("sw", "gt", "enables")
	p.add_edge("rc", "re", "enables")
	p.add_edge("re", "fork", "feeds")
	p.add_edge("gt", "filt", "converges")
	p.add_edge("fork", "filt", "converges")
	p.add_edge("filt", "tgt", "feeds")
	p.reasoning = "The Switch branch can look finished long before the puzzle is: it opens a Gate that only matters once the Receiver branch (through a Portal) powers the Remote Emitter. The remote beam then meets a fork: one way reaches the target directly but through a Filter of the WRONG colour (the target visibly stays dark); the other detours through the Gate and the Filter whose colour the target asks for. Work backward from the target colour: it needs that Filter, which sits behind the Gate, which needs the Switch - so both branches, and the splitter that feeds them, are required."


static func _plan_f(p: ProceduralPlanV3, rng: RandomNumberGenerator) -> void:
	p.title = "Prototype F - Shared One-Way as global decision (Phase 2A.1)"
	var cs := _two_colors(rng)
	p.params["remote_color"] = cs[0]
	p.params["filter_color"] = cs[1]
	p.params["wrong_color"] = third_color(cs[0], cs[1])
	p.params["keep_correct"] = 0
	p.add_stage("trunk", "trunk", false, 4)
	p.add_stage("pr", "prism", true)
	p.add_stage("zr", "route", false, 1)
	p.add_stage("ow", "one_way", false, 1) # shared X tile: ablation cannot see it (D94/2A.1)
	p.add_stage("sw", "switch", true)
	p.add_stage("gt", "gate")
	p.add_stage("red", "route", false, 1)
	p.add_stage("pt", "portal", true)
	p.add_stage("pt2", "portal", true)
	p.add_stage("rc", "receiver", true)
	p.add_stage("re", "remote", true, 0, cs[0])
	p.add_stage("rr", "route", false, 4)
	p.add_stage("filt", "filter", true, 0, cs[1])
	p.add_stage("tgt", "target", false, 0, cs[1])
	p.add_edge("trunk", "pr", "feeds")
	p.add_edge("pr", "zr", "feeds")
	p.add_edge("zr", "ow", "feeds")
	p.add_edge("ow", "sw", "feeds")
	p.add_edge("sw", "gt", "enables")
	p.add_edge("pr", "red", "feeds")
	p.add_edge("red", "pt", "feeds")
	p.add_edge("pt", "pt2", "feeds")
	p.add_edge("pt2", "rc", "feeds")
	p.add_edge("rc", "re", "enables")
	p.add_edge("re", "ow", "shares")
	p.add_edge("gt", "filt", "converges")
	p.add_edge("ow", "filt", "converges")
	p.add_edge("filt", "tgt", "feeds")
	p.reasoning = "One shared One-Way serves two beams from the Prism's channels. In the wrong state the Remote Emitter's beam PASSES straight through, hits the Switch, and still reaches the target - through a Filter of the wrong colour, so the target stays dark: a plausible wrong route. In the right state it REFLECTS the remote beam toward the Gate and the correct Filter, but then the Switch is fed by the Prism's other channel instead, which must itself be routed into the same tile. The Portal->Receiver->Remote chain, the shared tile's orientation and the Gate all have to agree before anything lights."
