extends TestCase
## tools/ci/stamp_version.sh must never derive the Android versionCode from the
## version name (1.0.2 -> 10002 would sit below an already-used code). The script is
## run against a COPY of the real presets/project in a scratch dir.

var _dir := ""
var _bash := ""


func before_each() -> void:
	_dir = ProjectSettings.globalize_path("user://stamp_test").replace("\\", "/")
	DirAccess.make_dir_recursive_absolute(_dir + "/tools/ci")
	for pair in [["res://tools/ci/stamp_version.sh", "/tools/ci/stamp_version.sh"], ["res://export_presets.cfg", "/export_presets.cfg"], ["res://project.godot", "/project.godot"]]:
		var f := FileAccess.open(pair[0], FileAccess.READ)
		var text := f.get_as_text().replace("\r\n", "\n")  # bash chokes on CRLF
		var o := FileAccess.open(_dir + pair[1], FileAccess.WRITE)
		o.store_string(text)
	var out := []
	_bash = "bash" if OS.execute("bash", ["-c", "echo ok"], out) == 0 and str(out).contains("ok") else ""


func after_each() -> void:
	OS.move_to_trash(_dir)


func _run(env: String, version: String) -> Array:
	var out := []
	var code := OS.execute(_bash, ["-c", "%s bash '%s/tools/ci/stamp_version.sh' %s" % [env, _dir, version]], out, true)
	return [code, str(out)]


func _codes() -> PackedStringArray:
	var codes := PackedStringArray()
	for line in FileAccess.get_file_as_string(_dir + "/export_presets.cfg").split("\n"):
		if line.begins_with("version/code="):
			codes.append(line.trim_prefix("version/code="))
	return codes


func test_version_name_never_rewrites_android_version_code() -> void:
	if _bash == "":
		return
	var before := _codes()
	eq(before.size(), 2, "both Android presets carry a code")
	eq(before[0], before[1], "presets agree")
	var r := _run("", "1.0.2")
	eq(r[0], 0, "stamp ok: " + r[1])
	eq(_codes(), before, "no override -> the preset's versionCode is kept, not derived from 1.0.2")
	ok(FileAccess.get_file_as_string(_dir + "/project.godot").contains('config/version="1.0.2"'))
	ok(FileAccess.get_file_as_string(_dir + "/export_presets.cfg").contains('version/name="1.0.2"'))


func test_explicit_override_raises_the_code_and_never_lowers_it() -> void:
	if _bash == "":
		return
	var cur := int(_codes()[0])
	var r := _run("ANDROID_VERSION_CODE=%d" % (cur + 1), "1.0.3")
	eq(r[0], 0, "override stamps: " + r[1])
	eq(_codes(), PackedStringArray([str(cur + 1), str(cur + 1)]))
	ne(_run("ANDROID_VERSION_CODE=%d" % cur, "1.0.3")[0], 0, "a lower code is refused")
	ne(_run("ANDROID_VERSION_CODE=abc", "1.0.3")[0], 0, "a non-numeric code is refused")
	eq(_codes(), PackedStringArray([str(cur + 1), str(cur + 1)]), "a refused run changes nothing")


func test_ios_build_number_still_derives_from_the_version() -> void:
	if _bash == "":
		return
	_run("", "1.2.3")
	ok(FileAccess.get_file_as_string(_dir + "/export_presets.cfg").contains('application/version="10203"'))
	ok(FileAccess.get_file_as_string(_dir + "/export_presets.cfg").contains('application/short_version="1.2.3"'))
