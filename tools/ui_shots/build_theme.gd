extends SceneTree
## Dev-only: regenerates themes/beamshift_theme.tres from BeamUI (the single source of the UI tokens).
##   godot --headless --path . --script res://tools/ui_shots/build_theme.gd
func _init() -> void:
	var err := ResourceSaver.save(BeamUI.build_theme(), "res://themes/beamshift_theme.tres")
	print("theme saved: ", error_string(err))
	quit(0 if err == OK else 1)
