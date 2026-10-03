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


func test_web_copy_matches_canonical_text() -> void:
	var html := FileAccess.get_file_as_string(Builder.OUT)
	ok(html != "", "docs/privacy-policy/index.html exists")
	ok(html == Builder.build_html(), "web copy is stale: run tools/privacy/build_policy_html.gd")
	ok(not html.contains("<script"), "no scripts on the policy page")
	ok(not html.contains("http://") and not html.contains("src="), "no external dependencies")


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
