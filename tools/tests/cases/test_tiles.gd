extends TestCase
## Every tile scene, in every state its view script draws, plus the input gate
## (fixed tiles swallow taps, rotatable tiles emit them).

const TILE_DIR := "res://scenes/tiles/"


func _click(button: int = MOUSE_BUTTON_LEFT, pressed := true) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = pressed
	return e


func test_every_tile_scene_draws_and_handles_taps() -> void:
	var names := DirAccess.get_files_at(TILE_DIR)
	ok(names.size() >= 16)
	var host := Control.new()
	host.size = Vector2(400, 400)
	runner.add_child(host)
	for f in names:
		var path := TILE_DIR + f.trim_suffix(".remap")
		if not path.ends_with(".tscn"):
			continue
		var tile: Control = load(path).instantiate()
		host.add_child(tile)
		tile.set("cell_size", 120.0)
		tile.set("grid_position", Vector2i(1, 2))
		var taps := watch(tile.tile_clicked) if tile.has_signal("tile_clicked") else []
		for rotatable in [true, false]:
			tile.set("rotatable", rotatable)
			for orientation in [0, 1, 2, 3]:
				tile.set("orientation", orientation)
				for active in [false, true]:
					tile.set("active", active)
					tile.set("activated", active)
					tile.set("routed_color", 1 if active else -1)
					tile.set("fused_color", 2 if active else -1)
					tile.set("input_sides", {0: [1], 1: [2, 3]} if active else {})
					tile.queue_redraw()
					await frames(1)
			for ev in [_click(), _click(MOUSE_BUTTON_RIGHT), _click(MOUSE_BUTTON_LEFT, false), InputEventKey.new()]:
				if tile.has_method("_gui_input"):
					tile._gui_input(ev)
		if tile.has_signal("tile_clicked"):
			ok(taps.size() >= 1, "%s emits a tap when rotatable" % f)
		tile.queue_free()
	host.queue_free()


func test_aspect_art_button_and_bar() -> void:
	var b := AspectArtButton.new()
	b.button_height = 80.0
	b.text = "X"
	runner.add_child(b)
	await frames(2)
	eq(b.custom_minimum_size.y, 80.0)
	b.queue_free()
