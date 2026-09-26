extends SceneTree
## Dev-only (scripts/tools/ is export-excluded): writes the 1024 px App Store icon the iOS
## preset points at. Apple rejects an App Store icon with an alpha channel, so the source
## is flattened onto the boot-splash colour, resized with Lanczos and saved as RGB8.
## Re-run after changing the app icon, then run a headless --import.
##
##   Godot_v4.7.1-stable_win64.exe --headless --path . -s scripts/tools/make_ios_icon.gd

const SOURCE := "res://assets/branding/bs_app_icon.png"
const TARGET := "res://assets/branding/bs_app_icon_ios_1024.png"
const SIZE := 1024


func _init() -> void:
	var src := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if src == null:
		push_error("could not load %s" % SOURCE)
		quit(1)
		return
	src.convert(Image.FORMAT_RGBA8)
	var bg: Color = ProjectSettings.get_setting("application/boot_splash/bg_color", Color(0, 0, 0, 1))
	var flat := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGB8)
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			flat.set_pixel(x, y, bg.lerp(Color(c.r, c.g, c.b), c.a))
	flat.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	var err := flat.save_png(ProjectSettings.globalize_path(TARGET))
	if err != OK:
		push_error("save failed: %s" % error_string(err))
		quit(1)
		return
	print("wrote %s (%dx%d RGB8, no alpha)" % [TARGET, flat.get_width(), flat.get_height()])
	quit(0)
