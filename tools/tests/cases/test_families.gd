extends TestCase
## Google Play Families hardening: the neutral Android age screen (local range only, Play Games gated,
## ads untouched) and the "Watch a short ad to reveal a hint" disclosure before every rewarded hint.

var _online: bool
var _gate: bool
var _backend_before: Variant
var _acct: Dictionary


func before_each() -> void:
	_online = InternetManager.is_online
	_gate = InternetManager.gate_passed
	InternetManager.is_online = true
	InternetManager.gate_passed = true
	_backend_before = AdManager._backend
	var a := PlatformAccount
	_acct = {"p": a.platform, "c": a.connected, "n": a.display_name, "a": a.play_games_setup_attempts, "m": a.last_message}
	Engine.time_scale = 1.0


func after_each() -> void:
	InternetManager.is_online = _online
	InternetManager.gate_passed = _gate
	AdManager._backend = _backend_before
	AdManager._sdk_ready = false
	AdManager._rewarded_ready = false
	AdManager._interstitial_ready = false
	AdManager.state = AdManager.State.IDLE
	var a := PlatformAccount
	a.platform = _acct["p"]
	a.connected = _acct["c"]
	a.display_name = _acct["n"]
	a.play_games_setup_attempts = _acct["a"]
	a.last_message = _acct["m"]
	Engine.time_scale = 1.0
	runner.get_tree().paused = false
	reset_scene()


func _age_screen() -> Control:
	var s: Control = load("res://scenes/ui/age_selection.tscn").instantiate()
	runner.add_child(s)
	await frames(2)
	return s


func _block() -> void:
	InternetManager.is_online = false


func _unblock() -> void:
	InternetManager.is_online = true


# --- Age screen -------------------------------------------------------------------------------------------

func test_screen_only_on_android_until_chosen() -> void:
	ok(AgeGroup.screen_required(AgeGroup.UNKNOWN, "Android"), "fresh Android asks")
	ok(not AgeGroup.screen_required(AgeGroup.UNKNOWN, "Windows"), "desktop never asks")
	ok(not AgeGroup.screen_required(AgeGroup.UNKNOWN, "iOS"), "iOS unchanged")
	for g in [AgeGroup.CHILD_12_OR_YOUNGER, AgeGroup.TEEN_13_TO_17, AgeGroup.ADULT_18_PLUS]:
		ok(not AgeGroup.screen_required(g, "Android"), "asked once")
	eq(SaveManager.age_group, AgeGroup.UNKNOWN, "fresh profile")
	eq(AgeGroup.sanitize(99), AgeGroup.UNKNOWN)
	eq(AgeGroup.sanitize(-1), AgeGroup.UNKNOWN)
	ok(not SaveManager.set_age_group(AgeGroup.UNKNOWN), "UNKNOWN is not a choice")
	ok(not SaveManager.set_age_group(7))


func test_age_screen_is_neutral() -> void:
	var s := await _age_screen()
	var buttons: Array[Button] = [s._child_button, s._teen_button, s._adult_button]
	eq(s._child_button.label_text, "12 OR YOUNGER")
	eq(s._teen_button.label_text, "13–17")
	eq(s._adult_button.label_text, "18 OR OLDER")
	for b in buttons:
		ok(not b.disabled and not b.button_pressed and not b.has_focus(), "nothing preselected")
		eq(b.custom_minimum_size, buttons[0].custom_minimum_size, "identical size")
		eq(b.theme_type_variation, buttons[0].theme_type_variation, "identical style")
		eq(b.get_theme_font_size("font_size"), buttons[0].get_theme_font_size("font_size"))
		ok(b.custom_minimum_size.y >= BeamUI.TOUCH_MIN, "large touch target")
	eq(SaveManager.age_group, AgeGroup.UNKNOWN, "showing the screen commits nothing")
	s.queue_free()


func test_no_play_games_while_unknown() -> void:
	PlatformAccount.platform = PlatformAccount.Platform.ANDROID
	PlatformAccount.play_games_setup_attempts = 0
	PlatformAccount.apply_age_group()
	eq(PlatformAccount.play_games_setup_attempts, 0, "no Play Games startup path (no is_authenticated / load player)")
	ok(not PlatformAccount.is_supported())
	PlatformAccount.sign_in()
	ok(not PlatformAccount.busy and PlatformAccount.last_message == "", "no sign-in attempt, no chooser")
	var s := await _age_screen()
	eq(PlatformAccount.play_games_setup_attempts, 0, "the age screen itself starts nothing")
	s.queue_free()


func test_choices_persist_locally() -> void:
	var cases := [
		["_child_button", AgeGroup.CHILD_12_OR_YOUNGER],
		["_teen_button", AgeGroup.TEEN_13_TO_17],
		["_adult_button", AgeGroup.ADULT_18_PLUS],
	]
	for c in cases:
		SaveManager._apply_data(SaveManager._default_data())
		PlatformAccount.platform = PlatformAccount.Platform.ANDROID
		PlatformAccount.play_games_setup_attempts = 0
		var s := await _age_screen()
		s.get(c[0]).pressed.emit()
		await frames(3)
		eq(SaveManager.age_group, c[1], "chosen %s" % c[0])
		SaveManager.age_group = AgeGroup.UNKNOWN
		SaveManager.load_game() # a restart reads the file
		eq(SaveManager.age_group, c[1], "persisted %s" % c[0])
		ok(not AgeGroup.screen_required(SaveManager.age_group, "Android"), "restart does not ask again")
		reset_scene()
	# only the range is stored: no exact age, birthday or name keys
	for key in SaveManager.to_dict():
		ok(not str(key).contains("birth") and not str(key).contains("email") and key != "age", "no personal field %s" % key)


func test_child_does_not_start_play_games() -> void:
	PlatformAccount.platform = PlatformAccount.Platform.ANDROID
	PlatformAccount.play_games_setup_attempts = 0
	var s := await _age_screen()
	s._child_button.pressed.emit()
	await frames(3)
	eq(SaveManager.age_group, AgeGroup.CHILD_12_OR_YOUNGER)
	eq(PlatformAccount.play_games_setup_attempts, 0, "CHILD: Play Games never initialised")
	ok(not PlatformAccount.is_supported(), "no account connection offered")
	PlatformAccount.sign_in()
	ok(not PlatformAccount.busy and not PlatformAccount.connected)


func test_teen_and_adult_keep_play_games_optional() -> void:
	for g in [AgeGroup.TEEN_13_TO_17, AgeGroup.ADULT_18_PLUS]:
		SaveManager.age_group = g
		PlatformAccount.platform = PlatformAccount.Platform.ANDROID
		PlatformAccount.play_games_setup_attempts = 0
		PlatformAccount.apply_age_group()
		eq(PlatformAccount.play_games_setup_attempts, 1, "13+: the optional silent check may start once")
		PlatformAccount.apply_age_group()
		eq(PlatformAccount.play_games_setup_attempts, 1, "idempotent")
		ok(PlatformAccount.is_supported())
		ok(not PlatformAccount.connected, "never mandatory: not connected until the player opts in")
	# iOS / desktop behaviour is untouched
	PlatformAccount.platform = PlatformAccount.Platform.IOS
	SaveManager.age_group = AgeGroup.UNKNOWN
	ok(PlatformAccount.is_supported(), "Sign in with Apple unaffected")
	PlatformAccount.platform = PlatformAccount.Platform.NONE
	ok(not PlatformAccount.is_supported())


func test_child_gameplay_and_local_save_work() -> void:
	SaveManager.set_age_group(AgeGroup.CHILD_12_OR_YOUNGER)
	PlatformAccount.platform = PlatformAccount.Platform.ANDROID
	GameManager.start_procedural_level(1)
	await frames(4)
	var game := current_scene()
	var grid: GridManager = game.get_node("%PuzzleGrid")
	var v := LevelManager.procedural_generator_version_for_new_play(1)
	var r := LevelManager.get_procedural_generation_result(1, v)
	solve_by_taps(grid, r["solution_orientations"])
	Engine.time_scale = 30.0
	var t0 := Time.get_ticks_msec()
	while not game._complete_popup.visible and Time.get_ticks_msec() - t0 < 6000:
		await frames(1)
	Engine.time_scale = 1.0
	ok(game._complete_popup.visible, "CHILD can finish a level without any account")
	ok(SaveManager.procedural_current_level >= 2, "progress recorded locally")
	ok(SaveManager.save_game())
	SaveManager.procedural_current_level = 1
	SaveManager.load_game()
	ok(SaveManager.procedural_current_level >= 2, "local save round-trips")
	eq(SaveManager.age_group, AgeGroup.CHILD_12_OR_YOUNGER)


func test_new_game_keeps_age_group() -> void:
	SaveManager.set_age_group(AgeGroup.TEEN_13_TO_17)
	SaveManager.procedural_current_level = 12
	ok(SaveManager.reset_main_progress_for_new_game())
	eq(SaveManager.age_group, AgeGroup.TEEN_13_TO_17)


func test_ads_stay_child_directed_for_everyone() -> void:
	ok(AdConfig.CHILD_DIRECTED, "child-directed for every age range")
	for g in [AgeGroup.UNKNOWN, AgeGroup.CHILD_12_OR_YOUNGER, AgeGroup.TEEN_13_TO_17, AgeGroup.ADULT_18_PLUS]:
		SaveManager.age_group = g
		ok(AdConfig.CHILD_DIRECTED)
	for f in ["res://scripts/ads/ad_backend_admob.gd", "res://scripts/ads/ad_config.gd", "res://scripts/managers/ad_manager.gd"]:
		var text := FileAccess.get_file_as_string(f)
		ok(not text.contains("age_group") and not text.contains("AgeGroup"), "%s must not read the age range" % f)
	var backend := FileAccess.get_file_as_string("res://scripts/ads/ad_backend_admob.gd")
	ok(backend.contains("TagForChildDirectedTreatment.TRUE") and backend.contains("TagForUnderAgeOfConsent.TRUE") and backend.contains("MAX_AD_CONTENT_RATING_G"))


func test_age_range_is_never_transmitted() -> void:
	var allowed := ["age_group.gd", "age_selection.gd", "platform_account.gd", "save_manager.gd", "studio_splash.gd"]
	var offenders: Array[String] = []
	var stack: Array[String] = ["res://scripts"]
	while not stack.is_empty():
		var dir: String = stack.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			stack.append(dir + "/" + sub)
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd") and not allowed.has(f):
				var t := FileAccess.get_file_as_string(dir + "/" + f)
				if t.contains("age_group") or t.contains("AgeGroup."):
					offenders.append(dir + "/" + f)
	eq(offenders.size(), 0, "unexpected readers of the age range: %s" % str(offenders))
	for f in ["res://scripts/managers/age_group.gd", "res://scripts/ui/age_selection.gd"]:
		var t := FileAccess.get_file_as_string(f)
		ok(not t.contains("HTTPRequest") and not t.contains("http"), "%s does no networking" % f)


func test_age_screen_respects_internet_blocker() -> void:
	PlatformAccount.platform = PlatformAccount.Platform.ANDROID
	var s := await _age_screen()
	_block()
	ok(InternetManager.is_blocking())
	s._adult_button.pressed.emit()
	s._child_button.pressed.emit()
	await frames(2)
	eq(SaveManager.age_group, AgeGroup.UNKNOWN, "no choice commits under the blocker")
	ok(is_instance_valid(s) and s.is_inside_tree(), "screen stays")
	s._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_unblock()
	s._teen_button.pressed.emit()
	await frames(3)
	eq(SaveManager.age_group, AgeGroup.TEEN_13_TO_17, "usable after reconnect")
	s._adult_button.pressed.emit()
	eq(SaveManager.age_group, AgeGroup.TEEN_13_TO_17, "second tap ignored")


# --- Rewarded hint disclosure -----------------------------------------------------------------------------

func _ad_game(show_mode := "reward") -> Array:
	var fake := AdBackendFake.new()
	fake.show_mode = show_mode
	AdManager.use_backend(fake)
	AdManager._sdk_ready = true
	fake.load_rewarded()
	await frames(2)
	AdManager._rewarded_ready = true
	GameManager.start_procedural_level(3)
	await frames(4)
	return [current_scene(), fake]


func test_hint_opens_disclosure_first() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	var shown := watch(game._hint.hint_shown)
	game._on_hint_pressed()
	await frames(2)
	ok(game._hint_dialog != null)
	ok(game._hint_dialog.get_parent() == game)
	eq(game._hint_dialog.get_global_rect().size, game.get_viewport().get_visible_rect().size, "modal covers the whole screen")
	var texts: Array[String] = []
	for n in game._hint_dialog.find_children("*", "Label", true, false):
		texts.append(n.text)
	ok(texts.has("GET A HINT?") and texts.has("Watch a short ad to reveal a hint."))
	eq(game._hint_dialog._cancel_button.label_text, "CANCEL")
	eq(game._hint_dialog._watch_button.label_text, "WATCH AD")
	eq(fake.rewarded_shows, 0, "no ad before WATCH AD")
	eq(shown.size(), 0)


func test_cancel_shows_nothing() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	var grid: GridManager = game.get_node("%PuzzleGrid")
	var before := grid.tile_orientations.duplicate()
	var moves: int = game.moves_used
	var shown := watch(game._hint.hint_shown)
	game._on_hint_pressed()
	await frames(2)
	game._hint_dialog._cancel_button.pressed.emit()
	await frames(3)
	ok(game._hint_dialog == null)
	eq(fake.rewarded_shows, 0)
	eq(shown.size(), 0)
	ok(not game._hint_used_this_attempt, "hint not consumed")
	ok(not game._rewarded_this_level)
	eq(grid.tile_orientations, before, "puzzle untouched")
	eq(game.moves_used, moves)
	ok(AdManager.is_rewarded_ready(), "the preloaded ad is still available")
	# Android Back on the disclosure is CANCEL too
	game._on_hint_pressed()
	await frames(2)
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(3)
	ok(game._hint_dialog == null and fake.rewarded_shows == 0)
	ok(not game._pause_menu.visible, "Back closed the disclosure instead of pausing")


func test_watch_ad_runs_existing_flow_once() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	var shown := watch(game._hint.hint_shown)
	game._on_hint_pressed()
	await frames(2)
	var dlg: HintAdDialog = game._hint_dialog
	dlg._watch_button.pressed.emit()
	dlg._watch_button.pressed.emit() # double tap
	dlg._cancel_button.pressed.emit() # late cancel
	await frames(4)
	eq(fake.rewarded_shows, 1, "exactly one rewarded ad")
	eq(shown.size(), 1, "reward callback grants exactly one hint")
	ok(game._hint_dialog == null)
	ok(game._rewarded_this_level and game._hint_used_this_attempt)


func test_repeated_taps_open_one_dialog_one_ad() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	for i in 4:
		game._on_hint_pressed()
	await frames(2)
	var dialogs := 0
	for c in game.get_children():
		if c is HintAdDialog and not c.is_queued_for_deletion():
			dialogs += 1
	eq(dialogs, 1, "one dialog")
	game._hint_dialog._watch_button.pressed.emit()
	game._on_hint_pressed()
	game._on_hint_pressed()
	await frames(4)
	eq(fake.rewarded_shows, 1, "one ad")


func test_no_reward_no_hint() -> void:
	for mode in ["close_no_reward", "fail"]:
		var pair := await _ad_game(mode)
		var game: Node = pair[0]
		var shown := watch(game._hint.hint_shown)
		game._on_hint_pressed()
		await frames(2)
		game._hint_dialog._watch_button.pressed.emit()
		await frames(4)
		eq(shown.size(), 0, "%s grants nothing" % mode)
		ok(not game._hint_used_this_attempt)
		eq(AdManager.state, AdManager.State.IDLE)
		reset_scene()


func test_not_ready_keeps_existing_feedback() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	AdManager._rewarded_ready = false
	var shown := watch(game._hint.hint_shown)
	game._on_hint_pressed()
	await frames(2)
	ok(game._hint_dialog == null, "no ad could start, so nothing to disclose")
	eq(shown.size(), 0, "no free hint")


func test_free_contexts_have_no_disclosure() -> void:
	AdManager._backend = null # desktop / no ad service
	GameManager.start_procedural_level(3)
	await frames(4)
	var game := current_scene()
	ok(not game._hint.permission_provider.is_valid(), "ads unsupported: free hint")
	var shown := watch(game._hint.hint_shown)
	game._on_hint_pressed()
	await frames(2)
	ok(game._hint_dialog == null)
	eq(shown.size(), 1, "free hint reveals immediately")
	reset_scene()
	GameManager.start_tutorial(1)
	await frames(4)
	var t := current_scene()
	ok(not t._hint.permission_provider.is_valid(), "tutorials are ad-free")
	ok(t._hint_dialog == null)


func test_no_forced_ads_keeps_rewarded_hint_option() -> void:
	SaveManager.set_entitlement(StoreConfig.NO_FORCED_ADS, true)
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	ok(AdManager.forced_ads_removed())
	var shown := watch(game._hint.hint_shown)
	game._on_hint_pressed()
	await frames(2)
	ok(game._hint_dialog != null, "the rewarded hint is still offered")
	game._hint_dialog._watch_button.pressed.emit()
	await frames(4)
	eq(fake.rewarded_shows, 1)
	eq(shown.size(), 1)
	SaveManager.set_entitlement(StoreConfig.NO_FORCED_ADS, false)


func test_hint_disclosure_respects_internet_blocker() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	game._on_hint_pressed()
	await frames(2)
	var dlg: HintAdDialog = game._hint_dialog
	_block()
	dlg._watch_button.pressed.emit()
	dlg._cancel_button.pressed.emit()
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(2)
	eq(fake.rewarded_shows, 0, "WATCH AD cannot fire under the blocker")
	ok(game._hint_dialog == dlg, "CANCEL / Back do not leak through either")
	_unblock()
	dlg._watch_button.pressed.emit()
	await frames(4)
	eq(fake.rewarded_shows, 1, "usable again after reconnect")


func _art_children_ignore_input(b: Control) -> void:
	for c in b.get_children():
		ok(c.get("mouse_filter") == Control.MOUSE_FILTER_IGNORE, "%s child %s ignores input" % [b.name, c.name])


func test_age_buttons_use_the_art_texture_and_ignore_child_input() -> void:
	var s := await _age_screen()
	for b: SettingsArtButton in [s._child_button, s._teen_button, s._adult_button]:
		eq(b.art.resource_path, "res://assets/ui/age_selection/bs_btn_age_selection.png")
		eq(b.text, "", "label is a child Label, not Button text")
		ok(b.size.y >= UIConstants.MIN_TOUCH_TARGET, "touch target")
		ok(b.size.x <= s.get_node("SafeArea/Center/Panel").size.x, "inside the panel")
		eq(b.base_modulate, Color.WHITE, "no age group is visually preferred")
		_art_children_ignore_input(b)
	eq(s._teen_button.size, s._child_button.size)
	s.queue_free()


func test_dialog_buttons_use_the_art_texture_and_ignore_child_input() -> void:
	for info in [false, true]:
		var d := HintAdDialog.new()
		d.info_only = info
		runner.add_child(d)
		await frames(2)
		var buttons: Array = [d._cancel_button] if info else [d._cancel_button, d._watch_button]
		for b: SettingsArtButton in buttons:
			eq(b.art.resource_path, "res://assets/ui/dialogs/bs_btn_dialog_action.png")
			ok(b.size.y >= UIConstants.MIN_TOUCH_TARGET, "touch target")
			ok(b.get_global_rect().end.x <= d.get_viewport().get_visible_rect().size.x, "fully visible")
			_art_children_ignore_input(b)
		eq(d._cancel_button.label_text, "OK" if info else "CANCEL")
		var got := watch(d.cancelled)
		d._cancel_button.pressed.emit()
		eq(got.size(), 1, "CANCEL/OK still emits cancelled")
		d.queue_free()
	var d2 := HintAdDialog.new()
	runner.add_child(d2)
	await frames(2)
	var conf := watch(d2.confirmed)
	d2._watch_button.pressed.emit()
	eq(conf.size(), 1, "WATCH AD still emits confirmed")
	ok(d2._watch_button.base_modulate.v >= d2._cancel_button.base_modulate.v, "primary is at least as bright as secondary")
	d2.queue_free()
