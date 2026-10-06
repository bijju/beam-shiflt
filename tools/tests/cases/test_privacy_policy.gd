extends TestCase
## Native Privacy Policy: canonical text, generated web copy in sync, Settings entry, scroll, Back.

const Builder := preload("res://tools/privacy/build_policy_html.gd")
const SCREEN := "res://scenes/ui/privacy_policy_screen.tscn"


func _scene(path: String) -> Control:
	var s: Control = load(path).instantiate()
	runner.add_child(s)
	await frames(4)
	return s


func test_canonical_text_facts() -> void:
	eq(PrivacyPolicyText.SECTIONS.size(), 14, "14 sections")
	var all := ""
	for s: Dictionary in PrivacyPolicyText.SECTIONS:
		all += "%s\n" % s["heading"]
		for b: Variant in s["blocks"]:
			all += (b if b is String else (b["sub"] if b is Dictionary else "\n".join(b))) + "\n"
	for must in ["MACLEPRO INC", "4 Sagez Studios Pvt. Ltd.", "sage@maclepro.in", "AdMob", "Play Games", "Sign in with Apple", "No Forced Ads", "child-directed"]:
		ok(all.contains(must), "mentions " + must)
	for forbidden in ["Firebase", "Firestore", "Gems", "Starter Pack", "iCloud", "Google Drive", "Game Center"]:
		ok(not all.contains(forbidden), "must not mention " + forbidden)
	ok(PrivacyPolicyText.SECTIONS[0]["heading"].begins_with("1. Summary"))
	ok(PrivacyPolicyText.SECTIONS[13]["heading"].begins_with("14. Contact"))


func _section_text(prefix: String) -> String:
	for s: Dictionary in PrivacyPolicyText.SECTIONS:
		if String(s["heading"]).begins_with(prefix):
			var t := ""
			for b: Variant in s["blocks"]:
				t += (b if b is String else (b["sub"] if b is Dictionary else "\n".join(b))) + "\n"
			return t.to_lower()
	return ""


func _has_all(text: String, parts: Array) -> bool:
	for p: String in parts:
		if not text.contains(p.to_lower()):
			return false
	return true


## Families pass: the policy must describe the age screen, Play Games gating and the rewarded-hint
## confirmation as implemented (concepts, not exact paragraphs - wording may be polished).
func test_policy_covers_age_screen_play_games_and_rewarded_hint() -> void:
	var children := _section_text("10.")
	ok(_has_all(children, ["android", "select an age range", "first time", "12 or younger", "13–17", "18 or older"]), "age selection + ranges")
	ok(_has_all(children, ["stored only on your device", "exact age", "date of birth"]), "local range, no exact age / DOB")
	ok(children.contains("does not send it to any beamshift server"), "not sent to BeamShift services")
	ok(children.contains("child-directed for every player"), "ads child-directed for all")
	ok(children.contains("not used to personalise ads"), "range never personalises ads")
	ok(not children.contains("clear app") and not children.contains("clear the app"), "no technical clear-data instructions here")
	var accounts := _section_text("3.")
	ok(_has_all(accounts, ["12 or younger", "does not start google play games sign-in", "does not offer"]), "under-13: BeamShift does not start/offer Play Games")
	ok(_has_all(accounts, ["13–17", "18 or older", "optional"]), "13+: optional")
	ok(_has_all(accounts, ["never require google play games", "leaderboards", "achievements", "cloud save"]), "Play Games not required / not used for cloud save, leaderboards, achievements")
	ok(accounts.contains("library") and accounts.contains("may run its own checks"), "provider-initiated startup behaviour is distinguished")
	ok(not accounts.contains("never initializes") and not accounts.contains("never initialises"), "no absolute Play Games claim")
	var ads := _section_text("5.")
	ok(_has_all(ads, ["rewarded hint", "confirm", "cancel", "watch ad", "reward requirement"]), "rewarded confirmation + reward wording")
	ok(not ads.contains("hint is always given"), "no unconditional hint promise")
	ok(_has_all(ads, ["child-directed for every player", "maximum content rating g", "not used for advertising"]), "ads child-directed, rating G, age range unused")
	ok(ads.contains("does not remove these optional ads"), "No Forced Ads keeps rewarded")
	ok(ads.contains("does not read the android advertising id"), "advertising-ID wording is about BeamShift's own code")
	ok(not ads.contains("belongs to") and not ads.contains("collects your advertising"), "no claim that BeamShift collects the advertising ID")
	ok(_section_text("6.").contains("does not remove the optional rewarded hint ads"), "purchase section agrees")
	var local := _section_text("2.")
	ok(_has_all(local, ["age range you selected", "never your exact age or date of birth"]), "local list includes the age range")
	ok(_has_all(_section_text("1."), ["12 or younger", "13–17", "18 or older", "does not use it to personalise ads"]), "summary mentions the age range")
	ok(_section_text("4.").contains("connectivity-check"), "internet requirement disclosure preserved")


func test_web_copy_matches_canonical_text() -> void:
	var html := FileAccess.get_file_as_string(Builder.OUT)
	ok(html != "", "docs/privacy-policy/index.html exists")
	ok(html == Builder.build_html(), "web copy is stale: run tools/privacy/build_policy_html.gd")
	ok(not html.contains("<script"), "no scripts on the policy page")
	ok(not html.contains("http://") and not html.contains("src="), "no external dependencies")


func test_public_policy_url_constant() -> void:
	eq(StoreConfig.PRIVACY_POLICY_URL, "https://abhilashdeva.github.io/beamshift-privacy/")
	ok(StoreConfig.PRIVACY_POLICY_URL.begins_with("https://"), "HTTPS")
	var src := FileAccess.get_file_as_string("res://scripts/ui/settings_menu.gd") + FileAccess.get_file_as_string("res://scripts/ui/privacy_policy_screen.gd")
	ok(not src.contains("shell_open"), "no external browser launch from the policy UI")


func test_screen_renders_all_sections_and_scrolls() -> void:
	var s := await _scene(SCREEN)
	# meta panel + 14 sections
	eq(s._content.get_child_count(), 15)
	var scroll: ScrollContainer = s._scroll
	var bar := scroll.get_v_scroll_bar()
	ok(bar.max_value > bar.page, "content is longer than the viewport and scrolls")
	scroll.scroll_vertical = int(bar.max_value)
	await frames(3)
	ok(scroll.scroll_vertical > 0, "reached the end")
	# no horizontal overflow: the column never exceeds the scroll viewport
	ok(s._content.size.x <= scroll.size.x + 1.0, "no horizontal clipping")
	ok(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	# Back stays on screen at the bottom of the scroll (it is outside the ScrollContainer)
	ok(not scroll.is_ancestor_of(s._back_button), "Back is outside the scroll")
	ok(s.get_viewport_rect().encloses(s._back_button.get_global_rect()), "Back remains visible")
	s.queue_free()


func test_scroll_content_is_mouse_transparent() -> void:
	var s := await _scene(SCREEN)
	for c in s._content.find_children("*", "Control", true, false):
		eq((c as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s ignores the mouse" % c.name)
	s.queue_free()


func test_back_returns_to_settings_even_after_scrolling() -> void:
	var s := await _scene(SCREEN)
	s._scroll.scroll_vertical = int(s._scroll.get_v_scroll_bar().max_value)
	await frames(2)
	s._back_button.pressed.emit()
	await frames(4)
	ok(current_scene().scene_file_path == GameManager.SETTINGS_SCENE, "Back -> Settings")
	reset_scene()


func test_system_back_returns_to_settings_and_respects_blocker() -> void:
	var s := await _scene(SCREEN)
	var was := InternetManager.is_online
	InternetManager.is_online = false
	InternetManager.gate_passed = true
	s._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(3)
	ok(current_scene().scene_file_path != GameManager.SETTINGS_SCENE, "no navigation under the blocker")
	InternetManager.is_online = was
	InternetManager._resolve_check(true)
	s._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(4)
	ok(current_scene().scene_file_path == GameManager.SETTINGS_SCENE)
	reset_scene()


func test_settings_button_opens_native_screen() -> void:
	var s := await _scene("res://scenes/ui/settings_menu.tscn")
	ok(s._privacy_policy.visible, "Privacy Policy is always listed")
	ok(s._privacy_policy.custom_minimum_size.y >= 96.0, "adequate touch target")
	s._privacy_policy.pressed.emit()
	await frames(4)
	ok(current_scene().scene_file_path == SCREEN, "opens the in-game screen (no OS.shell_open)")
	reset_scene()


## The project stretches 1080 logical px wide; physical 1080x1920 / 1080x2400 differ only in logical height.
func test_layout_fits_at_reference_sizes() -> void:
	for h in [1920, 2400]:
		var vp := SubViewport.new()
		vp.size = Vector2i(1080, h)
		runner.add_child(vp)
		var s: Control = load(SCREEN).instantiate()
		vp.add_child(s)
		await frames(5)
		var rect := Rect2(Vector2.ZERO, Vector2(1080, h))
		ok(rect.encloses(s._back_button.get_global_rect()), "Back inside %d" % h)
		ok(rect.encloses(s._scroll.get_global_rect()), "scroll inside %d" % h)
		ok(s._scroll.get_h_scroll_bar().max_value <= s._scroll.size.x + 1.0, "no horizontal overflow at %d" % h)
		ok(s._content.get_minimum_size().x <= s._scroll.size.x + 1.0, "content min width fits at %d" % h)
		for l in s._content.find_children("*", "Label", true, false):
			ok(l.get_global_rect().end.x <= 1080.0 - 20.0, "label inside right edge: " + str((l as Label).text).left(24))
		vp.queue_free()
