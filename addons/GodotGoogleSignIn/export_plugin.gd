@tool
extends EditorPlugin
## Wires the compiled GodotGoogleSignIn .aar into the Android export, mirroring
## addons/GodotPlayGameServices/export_plugin.gd's exact pattern. No autoload is added -
## unlike GodotPlayGameServices, GDScript talks to this plugin directly via
## Engine.get_singleton("GodotGoogleSignIn") (see scripts/ui/account_screen.gd), which
## needs no persistent wrapper node of its own.
##
## Only a DEBUG .aar exists as of this plugin's introduction (Phase 4A resume pass,
## 2026-09-28) - _get_android_libraries() returns nothing for a release export rather
## than referencing a release .aar that doesn't exist yet. Building the release variant
## is a follow-up step before any store-facing build uses this plugin.

var _export_plugin: AndroidExportPlugin


func _enter_tree() -> void:
	_export_plugin = AndroidExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	var _plugin_name = &"GodotGoogleSignIn"

	func _supports_platform(platform):
		if platform is EditorExportPlatformAndroid:
			return true
		return false

	func _get_android_libraries(platform, debug):
		if debug:
			return PackedStringArray([_plugin_name + "/bin/debug/" + _plugin_name + "-debug.aar"])
		# No release .aar has been built yet - see this file's own doc comment.
		return PackedStringArray()

	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if not _supports_platform(platform):
			return PackedStringArray()

		return PackedStringArray([
			"androidx.credentials:credentials:1.5.0",
			"androidx.credentials:credentials-play-services-auth:1.5.0",
			"com.google.android.libraries.identity.googleid:googleid:1.0.1",
			"org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.0",
		])

	func _get_name():
		return _plugin_name
