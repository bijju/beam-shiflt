class_name ProceduralSeed
extends RefCounted
## Deterministic seed derivation for the procedural level generator
## (Levels 1-2000). See PROCEDURAL_GENERATION.md "Determinism / seed
## derivation". Every random draw during generation must come from a
## RandomNumberGenerator seeded via rng_for_attempt() below - never
## randi()/OS entropy - so the same (level_number, generator_version,
## attempt) always derives the same seed, and therefore the same
## candidate LevelData.

## Combines level_number/generator_version/attempt into one deterministic
## seed via GDScript's stable string hash() - never randi() or OS
## entropy. hash() is deterministic across runs for the same input string
## within one Godot version (confirmed by this pass's own determinism
## test - see TEST_PLAN.md). If a future Godot upgrade ever changed
## hash()'s algorithm, ProceduralLevelGenerator.GENERATOR_VERSION must be
## bumped alongside it so already-active players' in-progress puzzles are
## unaffected - see that constant's own doc comment.
static func for_attempt(level_number: int, generator_version: int, attempt: int) -> int:
	var key := "beamshift-procedural|%d|%d|%d" % [level_number, generator_version, attempt]
	return int(hash(key))


## Convenience: a fresh RandomNumberGenerator already seeded for this
## exact attempt - ProceduralTemplates must draw every random choice from
## this and nothing else.
static func rng_for_attempt(level_number: int, generator_version: int, attempt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = for_attempt(level_number, generator_version, attempt)
	return rng
