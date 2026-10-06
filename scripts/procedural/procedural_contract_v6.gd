class_name ProceduralContractV6
extends RefCounted
## The ONE authoritative contract of generator V6 (Stages C-E, DECISIONS.md D125): Levels 1-4000.
##
## V6 is a NEW generator version, never a mutation of V1-V5: it reuses the V3-V5 composition pipeline
## (ProceduralProgressionV3 -> ProceduralFragmentsV3 -> ProceduralComposerV3 -> the real LaserSystem gates)
## but reads EVERYTHING level-dependent from this file - the band table, the mechanic introduction table,
## the Fusion / Selector / Phase policies, the complexity budget, the archetype / challenge / relief
## modifiers and the Level 4000 master profile. Nothing here touches ProceduralDifficultyContract (V3-V5
## still read it unchanged), so a saved V1-V5 puzzle keeps regenerating byte-identically.
##
## Pure data + deterministic functions: no RNG, no state. Every "random-looking" choice (archetype,
## relief, selector frequency) is a function of the level number (golden-ratio / hash sequences), so the
## same (level, V6) always yields the same profile.
##
## What a profile is: the generator-facing description of ONE level - which atoms may appear, the cores
## to start from (the "isolate -> +1 familiar -> +2 familiar -> advanced" introduction rule is encoded as
## three core stages per band), the complexity budget (points), the move window and the archetype bias.

const VERSION := 6
const MAX_LEVEL := 4000
## The deliberately special final level (see master_profile()).
const MASTER_LEVEL := 4000
## First level of each late mechanic (the user's V6 curve).
const PHASE_FIRST_LEVEL := 701
const SELECTOR_FIRST_LEVEL := 2001
const FUSION_FIRST_LEVEL := 401
const GRANDMASTER_FIRST_LEVEL := 3001

## Mechanic introduction table: first level at which a mechanic FAMILY may appear in a V6 puzzle.
## Kinds are the same strings ProceduralFragmentsV3.ATOMS lists. "multi_emitter" gates the shared-piece
## atoms (SH / SO) and the three-emitter chain (GG); "hazard" gates hazard tiles (a wrong ray ends on a
## hazard instead of a blocker).
const MECHANIC_FIRST := {
	"mirror": 1, "blocker": 1, "target_continuation": 1,
	"splitter": 21, "filter": 31, "portal": 41, "switch": 50, "gate": 50,
	"hazard": 76, "prism": 101, "one_way": 151, "receiver": 201, "remote": 201,
	"multi_emitter": 351, "fusion": 401, "phase": 701, "selector": 2001,
}

## Complexity points per DISTINCT load-bearing mechanic kind (ProceduralFragmentsV3.predict()'s kind_set).
## The budget of a level is the most points its atoms may add up to - a recipe that exceeds it is not
## drawn / escalated, so an eligible mechanic is never added merely because it is available.
const KIND_POINTS := {
	"splitter": 1, "filter": 1, "portal": 1, "switch": 1, "gate": 0, "prism": 2, "one_way": 2,
	"receiver": 1, "remote": 1, "fusion": 3, "phase": 3, "selector": 3,
}

## Archetypes (see archetype()). Names are an internal vocabulary, never shown to a player.
const ARCH_PRECISION := "PRECISION"
const ARCH_ROUTING := "ROUTING"
const ARCH_COLOR := "COLOR"
const ARCH_DEPENDENCY := "DEPENDENCY"
const ARCH_MULTI_BEAM := "MULTI_BEAM"
const ARCH_PHASE := "PHASE"
const ARCH_CONSTRAINT := "CONSTRAINT"
const ARCH_COMPACT := "COMPACT_TRICK"
const ARCH_GRAND := "GRAND"
const ALL_ARCHETYPES := [ARCH_PRECISION, ARCH_ROUTING, ARCH_COLOR, ARCH_DEPENDENCY, ARCH_MULTI_BEAM, ARCH_PHASE, ARCH_CONSTRAINT, ARCH_COMPACT, ARCH_GRAND]

## Which mechanic kinds make an atom list "belong" to an archetype (core weighting).
const _ARCH_KINDS := {
	"COLOR": ["filter", "prism", "fusion"],
	"DEPENDENCY": ["switch", "gate", "receiver", "remote"],
	"MULTI_BEAM": ["splitter", "receiver", "remote", "prism"],
	"PHASE": ["phase"],
	"CONSTRAINT": ["one_way", "portal", "gate"],
}

## Bands. Fields: from, to, name, code, moves [min, max], floors {deps, depth, inter, kinds} (the reasoning
## floors the BUILT board must reach), budget (complexity points), boards, stages (three core stages:
## isolate / +1 familiar / +2 familiar-or-advanced; atoms are ProceduralFragmentsV3 atom names), and the
## mechanic policies: fusion [probability, fragments], phase [probability, max_count, with_fusion],
## primary (the band's headline mechanic, informational / archetype weighting).
## Level 50 is where MEDIUM starts (tier "Medium"); 1-49 are Foundation..Portal (pre-Medium).
const _BANDS: Array = [
	{"from": 1, "to": 10, "name": "Foundation", "code": "FND", "moves": [3, 5], "floors": [0, 1, 0, 0], "budget": 1, "boards": [Vector2i(5, 7), Vector2i(5, 8), Vector2i(6, 8)],
		"stages": [[[]], [[], ["TM"]], [[], ["TM"]]]},
	{"from": 11, "to": 20, "name": "Routing", "code": "RTG", "moves": [4, 6], "floors": [0, 1, 0, 0], "budget": 1, "boards": [Vector2i(5, 8), Vector2i(6, 8), Vector2i(6, 9)],
		"stages": [[[], ["TM"]], [["TM"], ["TM"]], [["TM"], ["TM"]]]},
	{"from": 21, "to": 30, "name": "Splitting", "code": "SPL", "moves": [4, 7], "floors": [1, 2, 0, 1], "budget": 2, "boards": [Vector2i(5, 8), Vector2i(6, 8), Vector2i(6, 9)],
		"stages": [[["SB"]], [["SB"], ["SB", "TM"]], [["SB", "TM"], ["SB", "SB"]]]},
	{"from": 31, "to": 40, "name": "Color", "code": "CLR", "moves": [5, 7], "floors": [1, 2, 0, 1], "budget": 3, "boards": [Vector2i(5, 8), Vector2i(6, 8), Vector2i(6, 9)],
		"stages": [[["F"]], [["F"], ["F", "SB"]], [["F", "SB"], ["F", "TM"]]]},
	{"from": 41, "to": 49, "name": "Portal", "code": "PTL", "moves": [5, 8], "floors": [1, 2, 0, 1], "budget": 3, "boards": [Vector2i(5, 9), Vector2i(6, 9), Vector2i(6, 10)],
		"stages": [[["P"]], [["P"], ["P", "F"], ["P", "SB"]], [["P", "F"], ["P", "SB"], ["P", "F", "SB"]]]},
	{"from": 50, "to": 75, "name": "Switch Gate", "code": "SWG", "moves": [6, 9], "floors": [1, 3, 1, 2], "budget": 4, "boards": [Vector2i(5, 9), Vector2i(6, 9), Vector2i(6, 10)],
		"stages": [[["G"]], [["G", "F"], ["G", "P"], ["G", "SB"]], [["G", "F"], ["G", "P", "F"], ["SG"], ["G", "SB", "F"]]]},
	{"from": 76, "to": 100, "name": "Constraint", "code": "CST", "moves": [7, 10], "floors": [2, 3, 2, 3], "budget": 5, "boards": [Vector2i(6, 9), Vector2i(6, 10), Vector2i(7, 9)],
		"stages": [[["G", "F"], ["G", "P"], ["SG"]], [["G", "P", "F"], ["SG", "F"], ["G", "SB", "F"]], [["SG", "P", "F"], ["G", "P", "F"], ["SG", "F"]]]},
	{"from": 101, "to": 150, "name": "Prism", "code": "PRM", "moves": [8, 11], "floors": [2, 3, 1, 2], "budget": 6, "boards": [Vector2i(6, 9), Vector2i(6, 10), Vector2i(7, 9)],
		"stages": [[["PR"]], [["PR", "F"], ["PR", "P"]], [["PR", "F", "P"], ["PR", "G"], ["PG"]]]},
	{"from": 151, "to": 200, "name": "Directional", "code": "DIR", "moves": [8, 12], "floors": [2, 3, 1, 2], "budget": 7, "boards": [Vector2i(6, 10), Vector2i(7, 9), Vector2i(7, 10)],
		"stages": [[["OW"]], [["OW", "P"], ["OW", "F"], ["OW", "PR"]], [["OW", "F", "P"], ["OW", "G"], ["OW", "PR", "F"]]]},
	{"from": 201, "to": 275, "name": "Receiver", "code": "RCV", "moves": [9, 12], "floors": [2, 3, 1, 2], "budget": 7, "boards": [Vector2i(6, 10), Vector2i(7, 9), Vector2i(7, 10)],
		"stages": [[["H"]], [["H", "F"], ["H", "P"]], [["H", "G"], ["H", "PR"], ["H", "OW"], ["H", "SB"]]]},
	{"from": 276, "to": 350, "name": "Remote", "code": "RMT", "moves": [10, 13], "floors": [3, 4, 2, 3], "budget": 8, "boards": [Vector2i(6, 10), Vector2i(7, 10), Vector2i(7, 11)],
		"stages": [[["H", "H"]], [["H", "H", "F"], ["H", "G", "F"]], [["H", "H", "G"], ["PR", "H", "F"], ["SG", "H"], ["OW", "H", "F"]]]},
	{"from": 351, "to": 400, "name": "Multi-Emitter", "code": "MEM", "moves": [10, 14], "floors": [3, 4, 2, 3], "budget": 8, "boards": [Vector2i(7, 10), Vector2i(7, 11)],
		"stages": [[["SH"]], [["SH", "F"], ["GG"], ["SO"]], [["SH", "H", "F"], ["GG", "F"], ["SO", "F"]]]},
	{"from": 401, "to": 500, "name": "Fusion Intro", "code": "FSI", "moves": [10, 14], "floors": [3, 4, 2, 3], "budget": 8, "boards": [Vector2i(7, 10), Vector2i(7, 11)],
		"stages": [[["SG", "F"], ["H", "G", "F"]], [["PR", "H", "F"], ["SH", "F"]], [["GG", "F"], ["SG", "H", "F"]]],
		"fusion": [0.55, ["F1"]], "fusion_late": [0.5, ["F1", "F2"]]},
	{"from": 501, "to": 600, "name": "Fusion Combinations", "code": "FSC", "moves": [11, 15], "floors": [3, 5, 3, 3], "budget": 9, "boards": [Vector2i(7, 10), Vector2i(7, 11)],
		"stages": [[["SG", "F"], ["PR", "H", "F"], ["OW", "G", "F"]], [["PG", "F"], ["SH", "H", "F"]], [["GG", "F"], ["SG", "H", "F"], ["PR", "SG", "F"]]],
		"fusion": [0.5, ["F2", "F4", "F6"]]},
	{"from": 601, "to": 700, "name": "Advanced Fusion", "code": "FSA", "moves": [12, 16], "floors": [4, 5, 3, 4], "budget": 10, "boards": [Vector2i(7, 10), Vector2i(7, 11), Vector2i(8, 10)],
		"stages": [[["SG", "H", "F"], ["PG", "H", "F"]], [["GG", "H", "F"], ["SO", "H", "F"]], [["PR", "SG", "H", "F"], ["OW", "SG", "H", "F"]]],
		"fusion": [0.5, ["F3", "F5", "F7"]]},
	# --- Phase (generator V6 only). "PH" = the Phase gadget (a fixed Splitter whose loop returns a branch to a
	# rotatable Phase Shifter that has just been flipped to PHASE B by the straight beam). It always brings its
	# own Splitter, so a Phase level counts 4 points. The Phase roll is per level (probability), the count of
	# Phase gadgets is capped per band.
	{"from": 701, "to": 720, "name": "Phase Introduction", "code": "PHI", "moves": [4, 7], "floors": [2, 3, 1, 2], "budget": 4, "boards": [Vector2i(6, 9), Vector2i(6, 10), Vector2i(7, 9)],
		"stages": [[["PH"]], [["PH"]], [["PH", "TM"], ["PH"]]], "phase": [1.0, 1], "policy": [0.4, 0.5, "track", 0.0, 0.0]},
	{"from": 721, "to": 760, "name": "Phase Practice", "code": "PHP", "moves": [5, 8], "floors": [2, 3, 1, 2], "budget": 5, "boards": [Vector2i(6, 9), Vector2i(6, 10), Vector2i(7, 9)],
		"stages": [[["PH"]], [["PH", "TM"], ["PH"]], [["PH", "H", "PH"], ["PH", "TM"]]], "phase": [0.85, 2], "policy": [0.4, 0.5, "track", 0.0, 0.0]},
	{"from": 761, "to": 800, "name": "Phase Basics", "code": "PHB", "moves": [6, 9], "floors": [2, 4, 2, 2], "budget": 5, "boards": [Vector2i(6, 10), Vector2i(7, 9), Vector2i(7, 10)],
		"stages": [[["PH"]], [["PH", "SB"], ["PH", "TM"]], [["PH", "SB"], ["PH", "H", "PH"]]], "phase": [0.8, 2], "policy": [0.45, 0.5, "track", 0.0, 0.0]},
	{"from": 801, "to": 900, "name": "Phase Routing", "code": "PHR", "moves": [8, 12], "floors": [3, 4, 2, 3], "budget": 7, "boards": [Vector2i(7, 10), Vector2i(7, 11)],
		"stages": [[["PH", "P"], ["PH", "F"]], [["PH", "P", "F"], ["PH", "P"]], [["PH", "P", "F"], ["PH", "H", "PH"]]], "phase": [0.75, 2], "policy": [0.55, 0.4, "track", 0.1, 0.2]},
	{"from": 901, "to": 1000, "name": "Phase Dependency", "code": "PHD", "moves": [9, 13], "floors": [3, 5, 2, 3], "budget": 8, "boards": [Vector2i(7, 10), Vector2i(7, 11), Vector2i(8, 10)],
		"stages": [[["PH", "G"], ["PH", "H"]], [["PH", "G", "F"], ["PH", "H", "F"]], [["PH", "SG"], ["PH", "G", "H"], ["PH", "H", "F"]]], "phase": [0.75, 2], "policy": [0.55, 0.4, "track", 0.1, 0.2]},
	{"from": 1001, "to": 1200, "name": "Phase Expert", "code": "PHX", "moves": [11, 15], "floors": [4, 6, 3, 4], "budget": 9, "boards": [Vector2i(7, 11), Vector2i(8, 10)],
		"stages": [[["PH", "SG", "F"], ["PH", "H", "F"], ["PH", "G", "F"]], [["PH", "SG", "H"], ["PH", "G", "H"], ["PH", "H", "PH"]], [["PH", "H", "PH", "F"], ["PH", "H", "PH", "G"], ["PH", "SG", "H", "F"]]],
		"phase": [0.85, 2], "policy": [0.6, 0.35, "track", 0.1, 0.25]},
	{"from": 1201, "to": 1400, "name": "Phase Fusion", "code": "PHF", "moves": [12, 16], "floors": [4, 6, 3, 4], "budget": 10, "boards": [Vector2i(7, 11), Vector2i(8, 10)],
		"stages": [[["SG", "H", "F"], ["PR", "SG", "F"]], [["SG", "H", "F"], ["G", "H", "F", "P"]], [["PR", "SG", "H", "F"], ["OW", "SG", "F"]]],
		"fusion": [0.55, ["F2", "F3", "F4", "F5", "F6"]], "phase": [0.65, 2, true]},
	{"from": 1401, "to": 1600, "name": "Multi-Emitter Phase", "code": "PHM", "moves": [13, 17], "floors": [5, 7, 3, 4], "budget": 11, "boards": [Vector2i(7, 11), Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["PH", "SH", "F"], ["PH", "G", "F"]], [["PH", "SO", "F"], ["PH", "SH", "H"], ["PH", "GG"]], [["PH", "GG", "F"], ["PH", "SH", "H", "F"], ["PH", "H", "PH", "SH"]]],
		"phase": [0.85, 2]},
	{"from": 1601, "to": 1800, "name": "Complex Dependencies", "code": "CPX", "moves": [14, 18], "floors": [5, 8, 4, 5], "budget": 12, "boards": [Vector2i(7, 11), Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["PH", "H", "G", "F"], ["SG", "H", "G", "F"]], [["PH", "SG", "H"], ["PH", "G", "H", "F"]], [["PH", "H", "G", "F"], ["PH", "SG", "H", "F"], ["PR", "SG", "H", "F"]]],
		"fusion": [0.3, ["F2", "F3", "F4", "F5", "F6", "F7"]], "phase": [0.65, 2]},
	{"from": 1801, "to": 2000, "name": "Pre-Selector Mastery", "code": "PSM", "moves": [16, 21], "floors": [6, 8, 4, 5], "budget": 13, "boards": [Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["PH", "SG", "F"], ["PH", "G", "F"], ["PR", "SG", "H", "F"]], [["PH", "SG", "H"], ["PH", "GG", "F"], ["PH", "G", "H", "F"]], [["PH", "H", "PH", "SG"], ["PH", "SG", "H", "F"], ["PH", "SO", "F"], ["PH", "G", "H", "F"]]],
		"fusion": [0.3, ["F1", "F2", "F3", "F4", "F5", "F6", "F7"]], "phase": [0.6, 2, true]},
	# --- Selector era (generator V6 reuses the V5 selector machinery and the cores V5 measured; per-band policy below).
	{"from": 2001, "to": 2200, "name": "Selector Introduction", "code": "SEL", "moves": [17, 22], "floors": [5, 8, 4, 4], "budget": 8, "boards": [Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["SG", "F"], ["G", "F"], ["P", "F"]], [["SG", "H", "F"], ["G", "H", "F", "P"]], [["PR", "SG", "F"], ["OW", "SG", "F"], ["SG", "P", "F"]]],
		"selector": [0.55, ["SA", "SB", "SH"], 1, [1.0, 0.0, 0.0]], "phase": [0.5, 1, false]},
	{"from": 2201, "to": 2400, "name": "Selector Routing", "code": "SRT", "moves": [18, 23], "floors": [6, 9, 5, 5], "budget": 9, "boards": [Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["SG", "F"], ["G", "F", "P"]], [["SG", "H", "F"], ["OW", "SG", "F"]], [["PR", "SG", "F"], ["SG", "P", "F"], ["G", "H", "OW", "F"]]],
		"selector": [0.6, ["SA", "SB", "SC", "SD", "SH", "SL"], 1, [0.75, 0.25, 0.0]], "phase": [0.5, 1, false]},
	{"from": 2401, "to": 2600, "name": "Selector Phase", "code": "SPH", "moves": [18, 23], "floors": [6, 9, 5, 5], "budget": 14, "boards": [Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["PH", "SG", "F"], ["PH", "G", "F"]], [["PH", "SG", "H"], ["PH", "G", "F", "P"]], [["PH", "SG", "H", "F"], ["PH", "G", "H", "F"]]],
		"selector": [0.65, ["SA", "SC", "SD", "SH", "SL", "SN"], 2, [0.6, 0.35, 0.05]], "phase": [0.75, 2]},
	{"from": 2601, "to": 2800, "name": "Selector Fusion", "code": "SFU", "moves": [20, 26], "floors": [7, 10, 5, 5], "budget": 13, "boards": [Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["SG", "H", "F"], ["PR", "SG", "F"]], [["SG", "H", "F"], ["OW", "SG", "F"]], [["PR", "SG", "H", "F"], ["SG", "H", "G", "F"]]],
		"fusion": [0.45, ["F1", "F2", "F3", "F4", "F5", "F6", "F7"]],
		"selector": [0.7, ["SB", "SC", "SD", "SE", "SF", "SG", "SL", "SN", "SP"], 2, [0.3, 0.6, 0.1]], "phase": [0.4, 2, false]},
	{"from": 2801, "to": 3000, "name": "Selector Mastery", "code": "SMS", "moves": [21, 27], "floors": [8, 11, 6, 5], "budget": 14, "boards": [Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["SG", "H", "F"], ["PR", "SG", "F"]], [["SG", "H", "G", "F"], ["OW", "SG", "F"]], [["PR", "H", "G", "F"], ["SG", "H", "G", "F"], ["G", "H", "OW", "F"]]],
		"fusion": [0.4, ["F1", "F2", "F3", "F4", "F5", "F6", "F7"]],
		"selector": [0.76, ["SC", "SD", "SE", "SF", "SG", "SL", "SN", "SP"], 3, [0.1, 0.6, 0.3]], "phase": [0.5, 2, true]},
	# --- Grandmaster (the new Levels 3001-4000): combinations of EXISTING mechanics inside a curated envelope. The growth comes from
	# reasoning floors / mechanic combinations / Phase + Selector + Fusion together - never more columns, smaller tiles or padding.
	{"from": 3001, "to": 3200, "name": "Grandmaster I", "code": "GM1", "moves": [20, 26], "floors": [8, 11, 6, 5], "budget": 14, "boards": [Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["SG", "H", "F"], ["PR", "SG", "F"]], [["SG", "H", "G", "F"], ["G", "H", "F", "P"]], [["PR", "SG", "H", "F"], ["SG", "H", "G", "F"]]],
		"fusion": [0.35, ["F2", "F3", "F4", "F5", "F6", "F7"]],
		"selector": [0.7, ["SC", "SD", "SG", "SL", "SN", "SP"], 3, [0.2, 0.6, 0.2]], "phase": [0.7, 2, true]},
	{"from": 3201, "to": 3400, "name": "Grandmaster II", "code": "GM2", "moves": [20, 26], "floors": [9, 12, 6, 6], "budget": 15, "boards": [Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["SG", "H", "G", "F"], ["GG", "F"]], [["SG", "H", "G", "F"], ["G", "H", "OW", "F"]], [["PR", "H", "G", "F"], ["SG", "H", "G", "F"], ["GG", "H", "F"]]],
		"fusion": [0.3, ["F4", "F5", "F6"]],
		"selector": [0.75, ["SC", "SD", "SJ", "SL", "SN", "SP"], 3, [0.15, 0.55, 0.3]], "phase": [0.8, 3, true]},
	{"from": 3401, "to": 3600, "name": "Grandmaster III", "code": "GM3", "moves": [21, 27], "floors": [9, 12, 7, 6], "budget": 16, "boards": [Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["PR", "SG", "F"], ["PR", "SG", "H", "F"]], [["PR", "SG", "H", "F"], ["PR", "H", "G", "F"]], [["PR", "SG", "H", "F"], ["PR", "H", "G", "F"], ["PG", "H", "F"]]],
		"fusion": [0.5, ["F2", "F3", "F5", "F6", "F7"]],
		"selector": [0.75, ["SA", "SC", "SE", "SF", "SG", "SP"], 3, [0.1, 0.6, 0.3]], "phase": [0.7, 3, true]},
	{"from": 3601, "to": 3800, "name": "Extreme", "code": "XTR", "moves": [22, 28], "floors": [10, 13, 7, 6], "budget": 16, "boards": [Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["SG", "H", "G", "F"], ["GG", "H", "F"]], [["SG", "H", "G", "F"], ["SG", "G", "H", "OW"]], [["GG", "H", "G", "F"], ["SG", "H", "G", "F"], ["SG", "H", "OW", "F"]]],
		"fusion": [0.3, ["F4", "F5", "F6"]],
		"selector": [0.8, ["SC", "SD", "SJ", "SL", "SN", "SP"], 3, [0.1, 0.55, 0.35]], "phase": [0.8, 3, true]},
	{"from": 3801, "to": 3999, "name": "BeamShift Mastery", "code": "BSM", "moves": [22, 28], "floors": [10, 13, 7, 6], "budget": 17, "boards": [Vector2i(8, 10), Vector2i(8, 11)],
		"stages": [[["SG", "H", "G", "F"], ["PR", "SG", "H", "F"]], [["SG", "H", "G", "F"], ["GG", "H", "F"]], [["SG", "H", "G", "F"], ["PR", "H", "G", "F"], ["G", "H", "OW", "F"]]],
		"fusion": [0.35, ["F2", "F3", "F4", "F5", "F6", "F7"]],
		"selector": [0.8, ["SC", "SD", "SJ", "SL", "SN", "SP"], 3, [0.05, 0.55, 0.4]], "phase": [0.8, 3, true]},
	{"from": 4000, "to": 4000, "name": "Master Puzzle", "code": "MST", "moves": [24, 30], "floors": [9, 12, 7, 6], "budget": 17, "boards": [Vector2i(8, 11)],
		"stages": [[["SG", "H", "G", "F", "P"]], [["SG", "H", "G", "F", "P"]], [["SG", "H", "G", "F", "P"]]],
		"selector": [1.0, ["SC", "SD", "SL"], 2, [0.0, 1.0, 0.0]], "phase": [1.0, 2, false]},
]

## Selector gating by level (V6 mirrors the documented curve: no Selector + Phase + Fusion all at once early).
const SELECTOR_PHASE_FIRST := 2401
const SELECTOR_FUSION_FIRST := 2601


static func is_valid_level(level_number: int) -> bool:
	return level_number >= 1 and level_number <= MAX_LEVEL


static func _band(level_number: int) -> Dictionary:
	var n := clampi(level_number, 1, MAX_LEVEL)
	for b in _BANDS:
		if n >= int(b["from"]) and n <= int(b["to"]):
			return b
	return _BANDS[_BANDS.size() - 1]


static func band_name(level_number: int) -> String:
	return str(_band(level_number)["name"])


static func band_code(level_number: int) -> String:
	return str(_band(level_number)["code"])


static func band_start(level_number: int) -> int:
	return int(_band(level_number)["from"])


static func band_count() -> int:
	return _BANDS.size()


static func band_row(index: int) -> Dictionary:
	return _BANDS[index]


## Coarse difficulty tier of a level: Foundation (1-49), Medium (50-100), Hard (101-400), Fusion (401-700),
## Phase (701-2000), Selector (2001-3000), Grandmaster (3001-3999), Master (4000).
static func tier(level_number: int) -> String:
	if level_number >= MASTER_LEVEL:
		return "Master"
	if level_number >= GRANDMASTER_FIRST_LEVEL:
		return "Grandmaster"
	if level_number >= SELECTOR_FIRST_LEVEL:
		return "Selector"
	if level_number >= PHASE_FIRST_LEVEL:
		return "Phase"
	if level_number >= FUSION_FIRST_LEVEL:
		return "Fusion"
	if level_number >= 101:
		return "Hard"
	if level_number >= 50:
		return "Medium"
	return "Foundation"


static func is_medium_or_harder(level_number: int) -> bool:
	return level_number >= 50


## Mechanic FAMILIES available at a level (strings of MECHANIC_FIRST).
static func mechanics(level_number: int) -> Array[String]:
	var out: Array[String] = []
	for m in MECHANIC_FIRST:
		if level_number >= int(MECHANIC_FIRST[m]):
			out.append(m)
	return out


static func mechanic_available(level_number: int, mechanic: String) -> bool:
	return level_number >= int(MECHANIC_FIRST.get(mechanic, 1 << 30))


# --- Deterministic level modifiers --------------------------------------------------

const _PHI := 0.6180339887498949


## Modest challenge level (every 10th level, not the 50th / 4000th).
static func is_challenge(level_number: int) -> bool:
	return level_number % 10 == 0 and level_number % 50 != 0 and level_number != MASTER_LEVEL


## Stronger milestone level (every 50th level). Level 4000 is the special Master profile instead.
static func is_milestone(level_number: int) -> bool:
	return level_number % 50 == 0


## Relief: a deliberately smaller / cleaner / clever level after demanding ones. A deterministic low-discrepancy
## pattern (about 1 in 6 levels) that never lands on a challenge/milestone level and never on the first levels
## of a band (a new mechanic must be introduced at full clarity, never relieved away).
static func is_relief(level_number: int) -> bool:
	if level_number < 8 or level_number == MASTER_LEVEL or level_number % 10 == 0:
		return false
	if level_number - band_start(level_number) < 3:
		return false
	return fposmod(float(level_number) * _PHI + 0.311, 1.0) < 0.17


## Levels at which a band introduces a NEW mechanic family (splitter, filter, portal, switch/gate, prism, one-way, receiver, remote,
## multi-emitter, fusion, phase, selector). The first three levels of such a band are an introduction window: the mechanic is shown
## isolated at full clarity, so a challenge / milestone / relief modifier never raises its complexity there (the introduction rule:
## isolated first, then + one familiar system, then + two, then advanced).
const _INTRO_STARTS := [21, 31, 41, 50, 101, 151, 201, 276, 351, 401, 701, 2001]


static func is_intro_window(level_number: int) -> bool:
	for s in _INTRO_STARTS:
		if level_number >= s and level_number < s + 3:
			return true
	return false

## Position inside the band, 0..1, used for the isolate -> +1 -> +2 core stages.
static func band_progress(level_number: int) -> float:
	var b := _band(level_number)
	var span := int(b["to"]) - int(b["from"]) + 1
	return float(level_number - int(b["from"])) / float(maxi(span, 1))


## 0 = isolate the mechanic, 1 = +1 familiar system, 2 = +2 / advanced. A challenge steps one stage up, a
## milestone two, a relief one down (never below 0). Level 4000 always reads the last stage.
static func core_stage(level_number: int) -> int:
	var p := band_progress(level_number)
	if is_intro_window(level_number):
		return 0
	var stage := 0 if p < 0.30 else (1 if p < 0.65 else 2)
	if is_milestone(level_number):
		stage += 2
	elif is_challenge(level_number):
		stage += 1
	if is_relief(level_number):
		stage -= 1
	return clampi(stage, 0, 2)


## Archetype of a level: a deterministic hash-weighted pick from the archetypes the band's mechanics support.
## Same (level, V6) -> same archetype, always (no entropy). Challenge/milestone levels lean to the stronger
## archetypes; a relief level is COMPACT_TRICK or PRECISION.
static func archetype(level_number: int) -> String:
	if level_number == MASTER_LEVEL:
		return ARCH_GRAND
	var pool: Array[String] = _archetype_pool(level_number)
	if is_relief(level_number):
		return ARCH_COMPACT if (level_number % 2 == 0 or not pool.has(ARCH_PRECISION)) else ARCH_PRECISION
	if is_milestone(level_number) and pool.has(ARCH_GRAND):
		return ARCH_GRAND
	var h := int(hash("v6-archetype|%d" % level_number))
	return pool[posmod(h, pool.size())]


static func _archetype_pool(level_number: int) -> Array[String]:
	var pool: Array[String] = []
	if level_number >= 4:
		pool.append(ARCH_PRECISION)
	pool.append(ARCH_ROUTING)
	if level_number >= 31:
		pool.append(ARCH_COLOR)
	if level_number >= 50:
		pool.append(ARCH_DEPENDENCY)
	if level_number >= 21:
		pool.append(ARCH_MULTI_BEAM)
	if level_number >= PHASE_FIRST_LEVEL:
		pool.append(ARCH_PHASE)
	if level_number >= 76:
		pool.append(ARCH_CONSTRAINT)
	if level_number >= 12:
		pool.append(ARCH_COMPACT)
	if level_number >= 500:
		pool.append(ARCH_GRAND)
	if level_number >= GRANDMASTER_FIRST_LEVEL:
		pool.append(ARCH_GRAND) # Grandmaster levels favour GRAND (double weight)
	return pool


## Per-archetype generation bias: {moves_q (0..1 position inside the band's move window), board
## ("small" | "normal" | "large"), keep_bonus (extra already-correct fraction), hazard_frac (share of
## wrong-ray blockers turned into hazards, only where hazards exist), kinds (affinity kinds)}.
static func archetype_bias(arch: String) -> Dictionary:
	match arch:
		ARCH_PRECISION:
			return {"moves_q": 0.15, "board": "small", "keep_bonus": 0.1, "hazard_frac": 0.0}
		ARCH_ROUTING:
			return {"moves_q": 0.85, "board": "normal", "keep_bonus": 0.0, "hazard_frac": 0.0}
		ARCH_COLOR:
			return {"moves_q": 0.5, "board": "normal", "keep_bonus": 0.0, "hazard_frac": 0.0}
		ARCH_DEPENDENCY:
			return {"moves_q": 0.55, "board": "normal", "keep_bonus": 0.0, "hazard_frac": 0.0}
		ARCH_MULTI_BEAM:
			return {"moves_q": 0.6, "board": "large", "keep_bonus": 0.0, "hazard_frac": 0.0}
		ARCH_PHASE:
			return {"moves_q": 0.5, "board": "normal", "keep_bonus": 0.0, "hazard_frac": 0.0}
		ARCH_CONSTRAINT:
			return {"moves_q": 0.5, "board": "normal", "keep_bonus": 0.0, "hazard_frac": 0.6}
		ARCH_COMPACT:
			return {"moves_q": 0.0, "board": "small", "keep_bonus": 0.15, "hazard_frac": 0.0}
		ARCH_GRAND:
			return {"moves_q": 1.0, "board": "large", "keep_bonus": 0.0, "hazard_frac": 0.3}
	return {"moves_q": 0.5, "board": "normal", "keep_bonus": 0.0, "hazard_frac": 0.0}


# --- Policies ---------------------------------------------------------------------

## {probability, fragments} of the level's ONE Fusion roll. V6 keeps Fusion out of the first 400 levels, makes
## it the headline mechanic of 401-700 and a supporting one after; Selector levels use the band's own row.
static func fusion_policy(level_number: int) -> Dictionary:
	if level_number < FUSION_FIRST_LEVEL or level_number == MASTER_LEVEL:
		return {"fragments": [], "probability": 0.0}
	var b := _band(level_number)
	var key := "fusion"
	if b.has("fusion_late") and level_number >= int(b["from"]) + 50:
		key = "fusion_late"
	if not b.has(key):
		# Bands that define no Fusion row inherit a light, supporting Fusion share (the Fusion mechanic stays alive) once the
		# Phase introduction (701-800) is over; before that Phase stays the only new idea.
		if level_number >= 801:
			return {"fragments": ["F2", "F3", "F4", "F5", "F6"], "probability": 0.2}
		return {"fragments": [], "probability": 0.0}
	var row: Array = b[key]
	return {"fragments": (row[1] as Array).duplicate(), "probability": float(row[0])}


## {probability, max_count, with_fusion} of Phase. Before Level 701 it is always 0.
static func phase_policy(level_number: int) -> Dictionary:
	if level_number < PHASE_FIRST_LEVEL:
		return {"probability": 0.0, "max_count": 0, "with_fusion": false}
	var b := _band(level_number)
	if not b.has("phase"):
		return {"probability": 0.0, "max_count": 0, "with_fusion": false}
	var row: Array = b["phase"]
	return {"probability": float(row[0]), "max_count": int(row[1]), "with_fusion": row.size() > 2 and bool(row[2])}


## {frequency, count_weights, fragments, min_downstream_depth, has_selector}: V6's own table, same shape as
## ProceduralDifficultyContract.selector_policy() (which V6 does not read). Never before Level 2001; Level 2001
## always carries one simple Selector; the yes/no is a deterministic golden-ratio sequence, not an rng draw.
static func selector_policy(level_number: int) -> Dictionary:
	if level_number < SELECTOR_FIRST_LEVEL:
		return {"frequency": 0.0, "count_weights": [1.0, 0.0, 0.0], "fragments": [], "min_downstream_depth": 0, "has_selector": false}
	var b := _band(level_number)
	var row: Array = b["selector"] if b.has("selector") else _band(3000)["selector"]
	var phase := fposmod(float(level_number) * 0.6180339887498949 + 0.137, 1.0)
	return {
		"frequency": float(row[0]), "count_weights": (row[3] as Array).duplicate(), "fragments": (row[1] as Array).duplicate(),
		"min_downstream_depth": int(row[2]), "has_selector": phase < float(row[0]) or level_number == SELECTOR_FIRST_LEVEL or level_number == MASTER_LEVEL,
	}


# --- Budget / atoms ---------------------------------------------------------------

## Atom -> required mechanic families. An atom is allowed at a level when every family is available.
const _ATOM_NEEDS := {
	"F": ["filter"], "F2": ["filter"], "P": ["portal"], "SB": ["splitter"], "TM": ["target_continuation"],
	"G": ["switch", "gate"], "SG": ["splitter", "switch", "gate"], "PR": ["prism"], "PG": ["prism", "switch", "gate"],
	"SH": ["switch", "gate", "multi_emitter"], "H": ["receiver", "remote"], "OW": ["one_way"], "OH": ["one_way"],
	"SO": ["one_way", "switch", "gate", "multi_emitter"], "GG": ["switch", "gate", "multi_emitter"],
	"PH": ["phase", "splitter"],
}


static func atom_allowed(atom: String, level_number: int) -> bool:
	if not _ATOM_NEEDS.has(atom):
		return false
	for m in _ATOM_NEEDS[atom]:
		if not mechanic_available(level_number, m):
			return false
	return true


## Atoms ProceduralFragmentsV3 may ESCALATE with / start from at this level.
static func allowed_atoms(level_number: int) -> Array[String]:
	var out: Array[String] = []
	for a in _ATOM_NEEDS:
		# OH (a one-way the beam must PASS) is an optional extra of the hard bands: not before 401, and never while Phase is being
		# introduced (701-800: Phase is the only new idea, supporting mechanics stay familiar and simple).
		if a == "OH" and (level_number < 401 or (level_number >= 701 and level_number <= 800)):
			continue
		if atom_allowed(a, level_number):
			out.append(a)
	return out


## Complexity points of a set of mechanic kinds.
static func points_of_kinds(kinds: Array) -> int:
	var p := 0
	for k in kinds:
		p += int(KIND_POINTS.get(k, 0))
	return p


## Complexity budget of a level: the band's points, +1 on a challenge level, +2 on a milestone level, -1 on a
## relief level (never below the lowest band budget that still fits the band's own primary mechanic).
static func budget(level_number: int) -> int:
	var b := int(_band(level_number)["budget"])
	if is_intro_window(level_number):
		return clampi(b, 1, 19)
	if is_milestone(level_number):
		b += 2
	elif is_challenge(level_number):
		b += 1
	if is_relief(level_number) and b >= 8:
		b -= 1 # a relief level is smaller / cleaner; the budget only shrinks where the band has points to spare (never below its own primary mechanic)
	return clampi(b, 1, 19)


# --- Requirements / profile --------------------------------------------------------

## The move window of a level after the challenge / relief modifiers: a challenge raises the FLOOR by 1, a
## milestone by 2 and its ceiling by 1; a relief lowers the ceiling by 1 (never below the floor).
static func move_window(level_number: int) -> Vector2i:
	var b := _band(level_number)
	var lo := int(b["moves"][0])
	var hi := int(b["moves"][1])
	if is_milestone(level_number):
		lo += 2
		hi += 1
	elif is_challenge(level_number):
		lo += 1
	if is_relief(level_number):
		hi = maxi(lo, hi - 1)
	return Vector2i(lo, hi)


## The target move count the generator aims at: the archetype's quantile inside the move window, deterministic
## (no rng): PRECISION / COMPACT_TRICK sit at the bottom, ROUTING / GRAND at the top, a challenge shifts it
## up, a relief down. The generator's own rng only adds the +-1 variation.
static func target_moves(level_number: int) -> int:
	var w := move_window(level_number)
	var q: float = float(archetype_bias(archetype(level_number))["moves_q"])
	if is_milestone(level_number):
		q = maxf(q, 0.9)
	elif is_challenge(level_number):
		q = minf(1.0, q + 0.25)
	if is_relief(level_number):
		q = maxf(0.0, q - 0.3)
	if level_number <= 20:
		# Foundation / Routing ramp from the floor: Level 1 = the floor, Level 20 = the ceiling.
		q = minf(q, float(level_number - 1) / 19.0 + 0.1)
	return w.x + int(round(float(w.y - w.x) * q))


## Same dictionary shape as ProceduralDifficultyContract.get_difficulty_requirements() (everything the V3-V5
## pipeline reads), filled from the V6 tables, plus the "v6_*" keys.
static func requirements(level_number: int) -> Dictionary:
	var row := _band(level_number)
	var base := ProceduralDifficultyContract.get_difficulty_requirements(clampi(level_number, 1, 3000))
	var w := move_window(level_number)
	var floors: Array = row["floors"]
	var boost := 1 if (is_challenge(level_number) or is_milestone(level_number)) and level_number > 30 and not is_intro_window(level_number) else 0
	base["level_number"] = level_number
	base["band_name"] = row["name"]
	base["min_optimal_moves"] = w.x
	base["max_optimal_moves"] = w.y
	base["min_meaningful_dependencies"] = int(floors[0])
	base["max_meaningful_dependencies"] = ProceduralDifficultyContract.UNBOUNDED
	base["dependencies_soft"] = false
	base["min_dependency_depth"] = int(floors[1])
	base["max_dependency_depth"] = ProceduralDifficultyContract.UNBOUNDED
	base["min_mechanic_interactions"] = int(floors[2])
	base["min_distinct_mechanics"] = int(floors[3])
	base["preferred_board_profiles"] = _boards(level_number)
	base["unlocked_mechanics"] = mechanics(level_number)
	base["reject_single_route"] = level_number >= 21
	base["max_independent_move_fraction"] = 1.0 if level_number < 21 else (0.75 if level_number <= 100 else (0.6 if level_number <= 400 else (0.5 if level_number <= 1000 else 0.4)))
	# Challenge / milestone levels ask for slightly more reasoning (never padding): one more dependency / depth where the
	# band already requires dependencies at all.
	if boost > 0 and int(floors[0]) > 0:
		base["min_meaningful_dependencies"] = int(floors[0]) + 1
		base["min_dependency_depth"] = int(floors[1]) + 1
	# [min meaningful fraction, max plain fraction, greedy policy, keep-correct fraction, min plausible fraction]: a band may carry its own
	# (the Phase introduction bands are deliberately simple), else the V3 policy row of the level is read (V6 never edits that table).
	var pol5: Array
	if row.has("policy"):
		pol5 = (row["policy"] as Array).duplicate()
	else:
		var v3: Array = ProceduralDifficultyContract._policy_row(clampi(level_number, 1, 3000))
		pol5 = [v3[2], v3[3], v3[4], v3[5], v3[6]]
	base["min_meaningful_move_fraction"] = pol5[0]
	base["max_plain_move_fraction"] = pol5[1]
	base["greedy_policy"] = pol5[2]
	base["keep_correct_fraction"] = float(pol5[3]) + float(archetype_bias(archetype(level_number))["keep_bonus"])
	base["min_plausible_fraction"] = pol5[4]
	base["v6"] = true
	return base


static func _boards(level_number: int) -> Array[Vector2i]:
	var row := _band(level_number)
	var all: Array[Vector2i] = []
	for b in row["boards"]:
		all.append(b)
	var pref := str(archetype_bias(archetype(level_number))["board"])
	if all.size() <= 1 or pref == "normal":
		return all
	var by_area := all.duplicate()
	by_area.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x * a.y < b.x * b.y)
	var out: Array[Vector2i] = []
	if pref == "small":
		out.append(by_area[0])
		if by_area.size() > 2:
			out.append(by_area[1])
	else:
		out.append(by_area[by_area.size() - 1])
	return out


## The cores (atom lists) a level starts from: the band's stage pool for core_stage(). Atoms the level may not use
## (introduction table) or whose points exceed the budget are filtered by ProceduralFragmentsV3.
static func cores(level_number: int) -> Array:
	var row := _band(level_number)
	var stages: Array = row["stages"]
	return (stages[core_stage(level_number)] as Array).duplicate(true)


## Everything the generator needs about one level, in one dictionary (also the QA / test surface):
## {level, band, code, tier, archetype, challenge, milestone, relief, budget, stage, moves_window,
##  target_moves, mechanics, allowed_atoms, cores, fusion, phase, selector, master}.
static func profile(level_number: int) -> Dictionary:
	var arch := archetype(level_number)
	var w := move_window(level_number)
	return {
		"level": level_number, "band": band_name(level_number), "code": band_code(level_number), "tier": tier(level_number),
		"archetype": arch, "challenge": is_challenge(level_number), "milestone": is_milestone(level_number), "relief": is_relief(level_number),
		"budget": budget(level_number), "stage": core_stage(level_number), "moves_window": w, "target_moves": target_moves(level_number),
		"mechanics": mechanics(level_number), "allowed_atoms": allowed_atoms(level_number), "cores": cores(level_number),
		"fusion": fusion_policy(level_number), "phase": phase_policy(level_number), "selector": selector_policy(level_number),
		"master": level_number == MASTER_LEVEL, "bias": archetype_bias(arch),
	}


## Plain (Phase-free) cores for a level whose Phase roll failed on a band whose stage cores all need Phase.
const _PLAIN_CORES_MID := [["SG", "H", "F"], ["PG", "H", "F"], ["H", "G", "F", "P"], ["PR", "SG", "F"], ["OW", "SG", "F"], ["SG", "F"], ["PR", "H", "F"]]
const _PLAIN_CORES_LATE := [["SG", "H", "F"], ["PR", "SG", "F"], ["OW", "SG", "F"], ["SG", "P", "F"], ["H", "G", "F", "P"], ["GG", "F"], ["SG", "H", "G", "F"], ["PR", "H", "G", "F"], ["PG", "H", "F"], ["SO", "H", "F"]]


static func fallback_cores(level_number: int) -> Array:
	return (_PLAIN_CORES_MID if level_number < 1801 else _PLAIN_CORES_LATE).duplicate(true)
