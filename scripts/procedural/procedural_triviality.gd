class_name ProceduralTriviality
extends RefCounted
## Centralized triviality evaluator (Difficulty System Phase 1, DECISIONS.md
## D93): checks ProceduralComplexity metrics against
## ProceduralDifficultyContract requirements and returns deterministic
## rejection reasons. Phase 1 only REPORTS - ProceduralLevelGenerator does not
## yet reject on these (that is Phase 2, once templates can construct puzzles
## that pass instead of being regenerated until one does).
##
## "Not trivial" is not "hard enough": this only names the specific way a
## puzzle falls short of its band's contract. High move count never overrides
## a reasoning failure - see TRIVIAL_INDEPENDENT_ROTATIONS.

const TOO_FEW_MOVES := "TRIVIAL_TOO_FEW_MOVES"
const TOO_FEW_DEPENDENCIES := "TRIVIAL_TOO_FEW_DEPENDENCIES"
const TOO_SHALLOW := "TRIVIAL_TOO_SHALLOW"
const INDEPENDENT_ROTATIONS := "TRIVIAL_INDEPENDENT_ROTATIONS"
const SINGLE_OBVIOUS_ROUTE := "TRIVIAL_SINGLE_OBVIOUS_ROUTE"
const MECHANICS_NOT_INTERACTING := "TRIVIAL_MECHANICS_NOT_INTERACTING"
const PADDING := "TRIVIAL_PADDING"
const LATE_GAME_SINGLE_MECHANIC := "TRIVIAL_LATE_GAME_SINGLE_MECHANIC"
const SHORTCUT_SOLUTION := "TRIVIAL_SHORTCUT_SOLUTION"

## Non-triviality (over-shoot) reason: not a TRIVIAL_* - too many moves for the
## band is a tuning problem, reported separately so it is never mistaken for one.
const OVER_MOVE_CAP := "OVER_MAX_OPTIMAL_MOVES"

## An independent-rotation check needs enough moves to be meaningful.
const _INDEPENDENT_MIN_MOVES := 4


## Returns { "trivial": bool, "reasons": Array[String], "notes": Array[String] }.
## `reasons` holds only TRIVIAL_* ids (empty = passes). `notes` holds
## non-blocking observations (currently OVER_MOVE_CAP).
static func evaluate(metrics: Dictionary, requirements: Dictionary) -> Dictionary:
	var reasons: Array[String] = []
	var notes: Array[String] = []

	if not metrics.get("solved", false):
		return {"trivial": false, "reasons": ["NOT_SOLVED_BY_INTENDED_SOLUTION"], "notes": notes}

	var moves: int = metrics["optimal_moves"]
	if moves < requirements["min_optimal_moves"]:
		reasons.append(TOO_FEW_MOVES)
	if moves > requirements["max_optimal_moves"]:
		notes.append(OVER_MOVE_CAP)

	var deps: int = metrics["meaningful_dependency_count"]
	if deps < requirements["min_meaningful_dependencies"]:
		reasons.append(TOO_FEW_DEPENDENCIES)

	if metrics["dependency_depth"] < requirements["min_dependency_depth"]:
		reasons.append(TOO_SHALLOW)

	if metrics["mechanic_interaction_count"] < requirements["min_mechanic_interactions"]:
		reasons.append(MECHANICS_NOT_INTERACTING)

	if metrics["distinct_mechanic_kinds"] < requirements["min_distinct_mechanics"]:
		reasons.append(LATE_GAME_SINGLE_MECHANIC)

	if requirements["require_non_padding"] and metrics["padding_moves"] > 0:
		reasons.append(PADDING)

	if requirements["reject_single_route"] and metrics["is_single_route"]:
		reasons.append(SINGLE_OBVIOUS_ROUTE)

	var required: int = metrics["required_rotatables"]
	if required >= _INDEPENDENT_MIN_MOVES:
		var independent_share: float = float(metrics["plain_route_moves"]) / float(required)
		if independent_share > requirements["max_independent_move_fraction"]:
			reasons.append(INDEPENDENT_ROTATIONS)

	# A solver-verified optimum below the intended solution's move count means
	# a cheaper route exists that the template did not construct.
	if metrics["optimal_moves"] < metrics["intended_move_count"] and metrics["solver_states"] >= 0:
		reasons.append(SHORTCUT_SOLUTION)

	return {"trivial": not reasons.is_empty(), "reasons": reasons, "notes": notes}


## Convenience for a generated level: contract lookup + complexity + verdict.
## `generation` is ProceduralLevelGenerator.generate()'s return value; the
## intended solution comes from its "solution_orientations". `solver_result` is optional and dev-only
## (LevelSolver.analyze's dictionary) - this file never calls the solver.
static func evaluate_generated(level_number: int, generation: Dictionary, solver_result: Dictionary = {}) -> Dictionary:
	var requirements := ProceduralDifficultyContract.get_difficulty_requirements(level_number)
	var metrics := ProceduralComplexity.analyze(generation["level_data"], generation["solution_orientations"], solver_result)
	return {"requirements": requirements, "metrics": metrics, "verdict": evaluate(metrics, requirements)}
