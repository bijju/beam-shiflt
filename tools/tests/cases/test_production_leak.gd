extends TestCase
## Production QA-leak guard: in a production build NO QA/debug control may exist, be visible, or be reachable.
## In the internal-QA pass the negative assertions are skipped and the positive ones check the tools still exist.

var _online: bool


func before_each() -> void:
	_online = InternetManager.is_online
	InternetManager.is_online = true


func after_each() -> void:
	InternetManager.is_online = _online
	Engine.time_scale = 1.0
	reset_scene()


func _qa_buttons_on_menu(m: Node) -> Array:
	var found: Array = []
	for b in m.find_children("*", "BaseButton", true, false):
		var t := String(b.get("text")).to_upper()
		if t.contains("TEST") or t.contains("(QA)") or t.contains("V3") or t.contains("V5") or t.contains("V6") or t.contains("FUSION") or t.contains("SELECTOR"):
			found.append(b)
	return found


func test_build_config_gates_are_all_derived() -> void:
	eq(BuildConfig.IS_PRODUCTION_BUILD, not BuildConfig.QA_TOOLS, "QA_TOOLS is exactly the internal-QA mode")
	for flag in [LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING, LevelManager.UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING,
			LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON, LevelManager.SHOW_V3_PROTOTYPE_QA, LevelManager.SHOW_FUSION_TEST_QA,
			LevelManager.SHOW_SELECTOR_TEST_QA, LevelManager.SHOW_V5_TEST_QA, UIConstants.ALLOW_LARGE_GAMEPLAY_STACK_QA_OFFSET]:
		eq(flag, BuildConfig.QA_TOOLS, "every QA flag follows BuildConfig.QA_TOOLS")
	if BuildConfig.QA_TOOLS:
		return
	ok(not AdConfig.USE_TEST_IDS, "production never uses Google TEST ad ids")
	ok(not LevelManager.is_campaign_level_selectable(140) or SaveManager.is_campaign_level_unlocked(140), "no unlock-all for campaign")
	ok(not LevelManager.is_tutorial_level_selectable(11), "Era 2 tutorials are not force-unlocked on a fresh save")
	eq(LevelManager.procedural_generator_version_for_new_play(1), ProceduralLevelGenerator.GENERATOR_VERSION_V6, "new play is V6")


func test_main_menu_has_no_qa_controls() -> void:
	var m: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	runner.add_child(m)
	await frames(3)
	if BuildConfig.QA_TOOLS:
		ok(m._qa_level_select_button.visible, "internal QA keeps Level Select (QA)")
		ok(_qa_buttons_on_menu(m).size() >= 5, "internal QA keeps the V3/FUSION/SELECTOR/V5 test buttons")
	else:
		ok(not m._qa_level_select_button.visible, "Level Select (QA) hidden")
		ok(not m._qa_level_select_button.is_visible_in_tree(), "Level Select (QA) not visible in tree")
		ok(not m._qa_spacer.visible, "QA spacer hidden")
		for b in _qa_buttons_on_menu(m):
			ok(not b.is_visible_in_tree(), "QA button %s must not be visible" % b.name)
			ok(b.disabled or not b.is_visible_in_tree(), "QA button %s must not be clickable" % b.name)
	m.queue_free()


func test_gameplay_has_no_qa_controls() -> void:
	GameManager.start_procedural_level(60)
	await frames(4)
	var g := current_scene()
	ok(g != null and g.has_method("_on_qa_next_pressed"), "game scene loaded")
	if BuildConfig.QA_TOOLS:
		return
	ok(not g._qa_next_button.visible, "+50 hidden")
	ok(not g._qa_next_button.is_visible_in_tree(), "+50 not visible in tree")
	ok(not g._qa_debug_label.visible, "tutorial QA overlay hidden")
	var before: int = GameManager.current_procedural_level
	g._on_qa_next_pressed()
	await frames(3)
	eq(GameManager.current_procedural_level, before, "+50 handler is inert in production")
	eq(SaveManager.procedural_resume_level_number, before, "+50 never moves the resume pointer")
	for l in g.find_children("*", "Label", true, false):
		if not l.is_visible_in_tree():
			continue
		var t := String(l.text)
		ok(not (t.begins_with("V3 ") or t.begins_with("V4 ") or t.begins_with("V5 ") or t.begins_with("V6 ") or t.contains("V5 FAILED")
			or t.contains("TUTORIAL QA") or t.contains("FUSION QA") or t.contains("SELECTOR QA") or t.contains("V3 PROTO")), "generator/debug tag visible: '%s'" % t)


func test_qa_sessions_are_unreachable_in_production() -> void:
	if BuildConfig.QA_TOOLS:
		return
	GameManager.start_procedural_level(10)
	await frames(4)
	var g := current_scene()
	for flag in [GameManager.is_v3_prototype_mode, GameManager.is_fusion_test_mode, GameManager.is_selector_test_mode, GameManager.is_v5_test_mode]:
		ok(not flag, "no QA sandbox flag set by a normal start")
	ok(not g._is_v3_session(), "never a QA sandbox session")
	# Even a forced QA flag cannot activate a sandbox session: the session helpers also require the (false) LevelManager gate.
	GameManager.is_v5_test_mode = true
	GameManager.is_fusion_test_mode = true
	GameManager.is_selector_test_mode = true
	GameManager.is_v3_prototype_mode = true
	ok(not g._is_v3_session(), "QA session helpers stay false in production even with a stray flag")
	GameManager.is_v5_test_mode = false
	GameManager.is_fusion_test_mode = false
	GameManager.is_selector_test_mode = false
	GameManager.is_v3_prototype_mode = false


func test_level_complete_and_pause_have_no_qa_controls() -> void:
	if BuildConfig.QA_TOOLS:
		return
	GameManager.start_procedural_level(5)
	await frames(4)
	var g := current_scene()
	for p in [g._complete_popup, g._pause_menu]:
		if p == null:
			continue
		for b in p.find_children("*", "BaseButton", true, false):
			var t := String(b.get("text")).to_upper()
			ok(not (t.contains("QA") or t.contains("TEST") or t.contains("DEBUG")), "QA control in popup: %s" % b.name)
