class_name LevelMetrics
extends RefCounted
## Development-only design metrics + a rough, transparent difficulty
## ESTIMATE. This is explicitly not a scientific difficulty score - see
## DECISIONS.md ("Difficulty heuristic") for the exact formula and why it
## should not be treated as authoritative. Human level-design judgment
## always overrides this label.

enum DifficultyBand { TUTORIAL, EASY, MEDIUM, HARD, EXPERT }


## `solver_result` is optional (LevelSolver.analyze()'s return value) -
## when provided, optimal_moves/states_explored/shortest_solution_count
## are pulled from it instead of left at their "unknown" defaults.
static func compute(level_data: LevelData, solver_result: Dictionary = {}) -> Dictionary:
	var counts := {}
	for key in GridTypes.TileType.keys():
		counts[key] = 0
	var colors_used := {}

	var rotatable_count := 0
	var fixed_count := 0

	for t in level_data.tiles:
		var type_name: String = GridTypes.TileType.keys()[t.tile_type]
		counts[type_name] += 1

		if t.tile_type == GridTypes.TileType.MIRROR or t.tile_type == GridTypes.TileType.SPLITTER:
			if t.rotatable:
				rotatable_count += 1
			else:
				fixed_count += 1

		if t.tile_type == GridTypes.TileType.EMITTER or t.tile_type == GridTypes.TileType.FILTER:
			colors_used[t.color] = true
		if t.tile_type == GridTypes.TileType.TARGET and t.color != GridTypes.BeamColor.WHITE:
			colors_used[t.color] = true

	var metrics := {
		"grid_width": level_data.grid_width,
		"grid_height": level_data.grid_height,
		"total_tiles": level_data.tiles.size(),
		"rotatable_pieces": rotatable_count,
		"fixed_pieces": fixed_count,
		"emitters": counts[GridTypes.TileType.keys()[GridTypes.TileType.EMITTER]],
		"targets": counts[GridTypes.TileType.keys()[GridTypes.TileType.TARGET]],
		"mirrors": counts[GridTypes.TileType.keys()[GridTypes.TileType.MIRROR]],
		"splitters": counts[GridTypes.TileType.keys()[GridTypes.TileType.SPLITTER]],
		"blockers": counts[GridTypes.TileType.keys()[GridTypes.TileType.BLOCKER]],
		"filters": counts[GridTypes.TileType.keys()[GridTypes.TileType.FILTER]],
		"portal_tiles": counts[GridTypes.TileType.keys()[GridTypes.TileType.PORTAL]],
		"switches": counts[GridTypes.TileType.keys()[GridTypes.TileType.SWITCH]],
		"gates": counts[GridTypes.TileType.keys()[GridTypes.TileType.GATE]],
		"hazards": counts[GridTypes.TileType.keys()[GridTypes.TileType.HAZARD]],
		"colors_used": colors_used.size(),
		"declared_optimal_moves": level_data.optimal_moves,
		"solver_optimal_moves": solver_result.get("optimal_moves", -1),
		"states_explored": solver_result.get("states_explored", 0),
		"shortest_solution_count": solver_result.get("shortest_solution_count", 0),
	}

	metrics["mechanics_used"] = _mechanics_list(metrics)
	metrics["difficulty_band"] = _estimate_difficulty(metrics)
	metrics["difficulty_label"] = DifficultyBand.keys()[metrics["difficulty_band"]]

	return metrics


static func _mechanics_list(metrics: Dictionary) -> Array[String]:
	var list: Array[String] = []
	if metrics["mirrors"] > 0:
		list.append("Mirrors")
	if metrics["splitters"] > 0:
		list.append("Splitter")
	if metrics["colors_used"] > 0:
		list.append("Colored beams")
	if metrics["filters"] > 0:
		list.append("Filters")
	if metrics["portal_tiles"] > 0:
		list.append("Portal")
	if metrics["switches"] > 0 or metrics["gates"] > 0:
		list.append("Switch/Gate")
	if metrics["hazards"] > 0:
		list.append("Hazard")
	if metrics["emitters"] > 1:
		list.append("Multiple emitters")
	if metrics["targets"] > 1:
		list.append("Multiple targets")
	return list


## Transparent heuristic - deliberately simple and documented, not
## scientifically calibrated. See DECISIONS.md for the exact reasoning
## and an explicit note that this needs recalibration once real campaign
## levels exist to compare against.
static func _estimate_difficulty(metrics: Dictionary) -> DifficultyBand:
	var moves: int = metrics["declared_optimal_moves"]
	if metrics["solver_optimal_moves"] >= 0:
		moves = metrics["solver_optimal_moves"]

	var score := 0.0
	score += moves * 2.0
	score += metrics["rotatable_pieces"] * 1.5
	score += metrics["mechanics_used"].size() * 3.0
	if metrics["grid_width"] * metrics["grid_height"] > 25:
		score += 2.0

	if score <= 3.0:
		return DifficultyBand.TUTORIAL
	if score <= 7.0:
		return DifficultyBand.EASY
	if score <= 13.0:
		return DifficultyBand.MEDIUM
	if score <= 20.0:
		return DifficultyBand.HARD
	return DifficultyBand.EXPERT
