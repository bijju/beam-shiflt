class_name ProceduralPlanV3
extends RefCounted
## Logical puzzle plan for Generator V3 (Difficulty System Phase 2A, D94).
## A plan says WHAT the puzzle is - which mechanics are load-bearing, what
## depends on what, which colors matter, how many required rotations each
## route needs - and knows nothing about cells. ProceduralLayoutV3 turns a
## plan into a physical board; ProceduralGeneratorV3 then checks that every
## stage the plan promised is actually load-bearing on that board.
##
## Stage roles (`role`): "trunk", "route", "prism", "filter", "switch",
## "gate", "portal", "receiver", "remote", "one_way", "splitter", "fusion" (generator V4, D100), "target".
## `load_bearing` stages are verified by ablation after layout (a promised
## mechanic that turns out not to matter rejects the candidate).
## `turns` = rotatable mirrors that stage's route needs (the plan's own
## budget of required actions).

var archetype: String = ""
var title: String = ""
## Human-readable QA-only description of the intended reasoning. Never shown
## to the player.
var reasoning: String = ""
var stages: Array[Dictionary] = []
var edges: Array[Dictionary] = []
## Free-form layout parameters chosen by the planner: colors, flip_v,
## per-stage turn counts, number of rotatables that start already correct.
var params: Dictionary = {}
## Composed (Phase 2B) plans: the root of the line tree ProceduralComposerV3 realises
## (a line = source + ordered tokens; see ProceduralFragmentsV3). Empty for the six prototypes.
var lines: Array = []


func add_stage(id: String, role: String, load_bearing: bool = false, turns: int = 0, color: int = -1) -> void:
	stages.append({"id": id, "role": role, "load_bearing": load_bearing, "turns": turns, "color": color})


## kind: "enables" (switch->gate, receiver->remote), "feeds" (a beam or
## color/branch feeds the next stage), "shares" (two routes need one tile),
## "converges" (two chains must both hold for the final target).
func add_edge(from_id: String, to_id: String, kind: String) -> void:
	edges.append({"from": from_id, "to": to_id, "kind": kind})


func stage(id: String) -> Dictionary:
	for s in stages:
		if s["id"] == id:
			return s
	return {}


func total_turn_budget() -> int:
	var n := 0
	for s in stages:
		n += int(s["turns"])
	return n


func load_bearing_stage_ids() -> Array[String]:
	var ids: Array[String] = []
	for s in stages:
		if s["load_bearing"]:
			ids.append(s["id"])
	return ids


func edge_count(kind: String) -> int:
	var n := 0
	for e in edges:
		if e["kind"] == kind:
			n += 1
	return n


func summary() -> String:
	var parts: Array[String] = []
	for s in stages:
		if s["role"] != "route" and s["role"] != "trunk":
			parts.append(s["role"])
	return "%s [%s]" % [archetype, ", ".join(parts)]
