class_name StarScoring
extends RefCounted
## The ONE star rule for every level population (Phase 4, D102). Pure static functions, no state, no autoload.
## Level data never carries star thresholds.
##
## Rule V1, with OPTIMAL = authoritative_optimal():
##   moves <= OPTIMAL + THREE_STAR_MARGIN (2)  -> 3 stars
##   moves <= OPTIMAL + TWO_STAR_MARGIN   (6)  -> 2 stars
##   otherwise                                  -> 1 star (a legitimate solve is never worth 0)
## A Hint GRANTED during the attempt caps the result at 2 stars (never below the computed value).
## Fewer moves than OPTIMAL never crashes and is never punished: 3 stars + a QA warning (stale metadata,
## unverified intended_moves or a real shorter solution/shortcut).

const THREE_STAR_MARGIN := 2
const TWO_STAR_MARGIN := 6
const HINT_STAR_CAP := 2


static func stars_for(optimal: int, moves: int, hint_used: bool = false) -> int:
	if moves < optimal:
		push_warning("StarScoring: %d moves is BELOW the declared optimal %d (stale intended_moves, unverified metadata or a shorter solution)" % [moves, optimal])
	var stars := 1
	if moves <= optimal + THREE_STAR_MARGIN:
		stars = 3
	elif moves <= optimal + TWO_STAR_MARGIN:
		stars = 2
	if hint_used:
		stars = mini(stars, HINT_STAR_CAP)
	return stars


## Fallback chain: (1) verified_optimal_moves if >= 0, (2) intended_moves if > 0, (3) the level's own
## legacy optimal_moves. `result` is a ProceduralLevelGenerator.generate() dictionary (or {} for handcrafted
## levels, which only have level.optimal_moves).
static func authoritative_optimal(level: LevelData, result: Dictionary = {}) -> int:
	if int(result.get("verified_optimal_moves", -1)) >= 0:
		return int(result["verified_optimal_moves"])
	if int(result.get("intended_moves", 0)) > 0:
		return int(result["intended_moves"])
	return level.optimal_moves if level != null else 1
