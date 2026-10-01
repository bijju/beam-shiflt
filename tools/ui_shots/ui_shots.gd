extends Node
## Dev-only render driver (tools/ is export-excluded). Run NON-headless so real frames exist:
##   godot --path . --resolution 1080x1920 res://tools/ui_shots/ui_shots.tscn -- out=<dir> [only=a,b]
## Saves one PNG per screen into <dir> named <screen>_<height>.png.

const SCREENS := ["main_menu", "settings", "tutorial_select", "level_select", "account", "about", "game", "game_tutorial", "pause", "level_complete", "tutorial_complete", "dialog_confirm"]

var _out := ""
var _only: PackedStringArray = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			_out = a.substr(4)
		elif a.begins_with("only="):
			_only = a.substr(5).split(",")
	print("SHOTS start out=", _out, " only=", _only)
	DirAccess.make_dir_recursive_absolute(_out)
	InternetManager._periodic_timer.stop()
	InternetManager.is_online = true
	SaveManager.campaign_highest_unlocked_level = 14
	SaveManager.record_campaign_level_result(1, 3, 3, 140)
	SaveManager.record_campaign_level_result(2, 6, 2, 140)
	SaveManager.record_campaign_level_result(3, 9, 1, 140)
	SaveManager.record_campaign_level_result(4, 9, 3, 140)
	SaveManager.campaign_highest_unlocked_level = 14
	SaveManager.record_tutorial_level_result(1, 34)
	SaveManager.record_tutorial_level_result(2, 34)
	for s in SCREENS:
		if _only.size() > 0 and not (s in _only):
			continue
		await _shoot(s)
	InternetManager._http_request.cancel_request()
	get_tree().quit()
	OS.kill(OS.get_process_id())  # a pending connectivity probe can otherwise stall process exit


func _shoot(name: String) -> void:
	print("SHOTS shoot ", name)
	var node: Node = null
	match name:
		"main_menu": node = load("res://scenes/ui/main_menu.tscn").instantiate()
		"settings": node = load("res://scenes/ui/settings_menu.tscn").instantiate()
		"tutorial_select": node = load("res://scenes/ui/tutorial_select.tscn").instantiate()
		"level_select": node = load("res://scenes/ui/level_select.tscn").instantiate()
		"account": node = load("res://scenes/ui/account_screen.tscn").instantiate()
		"about": node = load("res://scenes/ui/about_screen.tscn").instantiate()
		"game", "game_tutorial", "pause", "level_complete", "tutorial_complete":
			GameManager.is_tutorial_mode = name in ["game_tutorial", "tutorial_complete"]
			GameManager.is_procedural_mode = false
			GameManager.entered_via_level_select = true
			GameManager.current_level_id = 27
			GameManager.current_tutorial_id = 3
			node = load("res://scenes/gameplay/game.tscn").instantiate()
		"dialog_confirm":
			node = load("res://scenes/ui/main_menu.tscn").instantiate()
		"internet_gate": node = load("res://scenes/ui/internet_gate.tscn").instantiate()
	add_child(node)
	for i in 14:
		await get_tree().process_frame
	match name:
		"main_menu":
			node._quit_button.visible = false  # phones hide Quit
			node._layout_hero_elements()
		"pause": node._on_pause_pressed()
		"level_complete": node._complete_popup.show_result(7, 2, true, 5, false, false, true)
		"tutorial_complete": node._tutorial_complete_popup.show_result(false)
		"internet_gate":
			node._on_check_completed(false)
		"dialog_confirm":
			SaveManager.procedural_current_level = 12
			node._show_new_game_confirmation()
	for i in 10:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	print("SHOTS saving ", name, " ", img.get_size())
	img.save_png("%s/%s_%d.png" % [_out, name, int(get_viewport().get_visible_rect().size.y)])
	node.queue_free()
	await get_tree().process_frame
	SaveManager.procedural_current_level = 1
