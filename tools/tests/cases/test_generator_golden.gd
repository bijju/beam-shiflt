extends TestCase
## Golden fingerprints (Stage C, D125): the meaningful puzzle data of representative levels of EVERY generator version is
## hashed (GeneratorFingerprint.fingerprint: dimensions, every tile with position / direction / orientation / colour / ids,
## the intended solution, the version and the intended move count - never presentation metadata) and compared with a file
## captured BEFORE V6 existed (V1-V5) or after V6's final tuning (V6). A frozen generator must never change: a saved puzzle of
## that version has to regenerate byte-identically.
##
## A diff here is a STOP condition, not a snapshot to refresh. Re-capturing a golden is only legitimate for V6 and only for a
## deliberate V6 change (before any V6 puzzle is released). The wide V1-V5 files were captured from the pristine HEAD
## procedural code in a separate project copy. The dev tool scripts/tools/generator_fingerprint.tscn checks all of them
## (including the slow V5 set) in parallel processes.

const GOLDEN_DIR := "res://tools/tests/golden/"


func _golden(file: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(GOLDEN_DIR + file)
	var parsed: Variant = JSON.parse_string(text)
	ok(typeof(parsed) == TYPE_DICTIONARY and not (parsed as Dictionary).is_empty(), "golden %s loads" % file)
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


## Compares every `stride`-th entry of a golden file (stride 1 = all).
func _check(version: int, file: String, stride: int = 1, max_entries: int = 9999) -> int:
	var golden := _golden(file)
	var keys := golden.keys()
	keys.sort_custom(func(a, b): return int(str(a).split("|")[1]) < int(str(b).split("|")[1]))
	var compared := 0
	var i := 0
	for k in keys:
		i += 1
		if (i - 1) % stride != 0 or compared >= max_entries:
			continue
		var level := int(str(k).split("|")[1])
		var r := ProceduralLevelGenerator.generate(level, version)
		eq(GeneratorFingerprint.fingerprint(r, version), golden[k], "V%d L%d fingerprint unchanged" % [version, level])
		compared += 1
	return compared


func test_v1_golden_unchanged() -> void:
	ok(_check(1, "generator_v1.json") >= 17)
	ok(_check(1, "generator_v1_wide.json") >= 60)


func test_v2_golden_unchanged() -> void:
	ok(_check(2, "generator_v2.json") >= 17)
	ok(_check(2, "generator_v2_wide.json") >= 60)


func test_v3_golden_unchanged() -> void:
	ok(_check(3, "generator_v3.json") >= 18)
	ok(_check(3, "generator_v3_wide.json", 2) >= 30)


func test_v4_golden_unchanged() -> void:
	ok(_check(4, "generator_v4.json") >= 26)
	ok(_check(4, "generator_v4_wide.json", 2) >= 30)


func test_v5_golden_unchanged() -> void:
	# V5 is slow (~1.5 s per level): a stride across the whole file here, the full set in the dev tool.
	ok(_check(5, "generator_v5.json", 6) >= 4)
	ok(_check(5, "generator_v5_wide.json", 9) >= 2)


func test_v6_golden_anchor_fingerprints() -> void:
	# The 42 V6 anchors (the levels named in the Stage C-E brief). A deliberate V6 retune re-captures this file; nothing else may.
	var golden := _golden("generator_v6.json")
	eq(golden.size(), 42, "42 V6 anchors")
	var checked := 0
	for level in [1, 10, 30, 49, 50, 100, 300, 500, 680, 701, 720, 900, 1000, 1400, 2001, 3001, 3999, 4000]:
		var key := "6|%d" % level
		ok(golden.has(key), "golden has %s" % key)
		var r := ProceduralLevelGenerator.generate(level, 6)
		eq(GeneratorFingerprint.fingerprint(r, 6), golden.get(key, ""), "V6 L%d fingerprint" % level)
		checked += 1
	eq(checked, 18)


func test_v6_same_level_same_fingerprint_repeatedly() -> void:
	for level in [1, 50, 701, 1200]:
		var first := GeneratorFingerprint.fingerprint(ProceduralLevelGenerator.generate(level, 6), 6)
		for _i in range(2):
			eq(GeneratorFingerprint.fingerprint(ProceduralLevelGenerator.generate(level, 6), 6), first, "V6 L%d repeats" % level)
