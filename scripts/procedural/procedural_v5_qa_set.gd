class_name ProceduralV5QaSet
extends RefCounted
## DEV-ONLY curated sample of generator-V5 levels for manual difficulty review (Selector Phase S3, D110). Behind Main
## Menu's "V5 TEST" (LevelManager.SHOW_V5_TEST_QA); never touches saves, stars, ads or the completion counter
## (game.gd's _is_v3_session() containment). The list spans every V5 band, first to last level; the real generator
## produces each puzzle (nothing here is authored), so a QA pass exercises exactly what a player would meet.

const LEVELS: Array[int] = [2001, 2050, 2201, 2351, 2500, 2651, 2800, 2900, 3000]
const COUNT := 9


## 1-based index -> the generated puzzle (the full ProceduralLevelGenerator.generate() result).
static func get_puzzle(index: int) -> Dictionary:
	return ProceduralLevelGenerator.generate(level_for(index), ProceduralLevelGenerator.GENERATOR_VERSION_V5)


static func level_for(index: int) -> int:
	return LEVELS[clampi(index, 1, COUNT) - 1]
