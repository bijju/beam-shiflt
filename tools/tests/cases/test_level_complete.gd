extends TestCase
## Level Complete redesign: presentation contract of LevelCompletePopup (values come from game.gd, popup never scores).


func _popup() -> Control:
	var p: Control = load("res://scenes/ui/level_complete_popup.tscn").instantiate()
	runner.add_child(p)
	await frames(3)
	return p


func _earned_count(p: Control) -> int:
	var n := 0
	for s in p._stars:
		if s.modulate.is_equal_approx(Color.WHITE):
			n += 1
	return n


func test_star_counts_and_badge_text() -> void:
	var p := await _popup()
	var expect := {1: "LEVEL CLEARED", 2: "GREAT CLEAR!", 3: "PERFECT CLEAR!"}
	for st in [1, 2, 3]:
		p.show_result(8, st, true, 7, false, false, true, 10, 24)
		p.skip_presentation()
		eq(_earned_count(p), st, "%d earned stars" % st)
		eq(p._result_label.text, expect[st])
		eq(p._result_sub_label.text, "%d STAR CLEAR" % st)
		ok(p._stars_holder.visible and p._badge_holder.visible)
	p.queue_free()


func test_hint_capped_two_star_shows_note_and_two_stars() -> void:
	var p := await _popup()
	p.show_result(8, 2, true, -1, false, true, true, 10, 24)
	p.skip_presentation()
	ok(p._hint_used_label.visible)
	eq(_earned_count(p), 2)
	p.show_result(8, 2, true, -1, false, false, true, 10, 24)
	ok(not p._hint_used_label.visible, "note does not leak into the next result")
	p.queue_free()


func test_values_and_fallbacks() -> void:
	var p := await _popup()
	p.show_result(8, 3, true, 7, false, false, true, 10, 24)
	p.skip_presentation()
	eq([p._moves_label.text, p._target_label.text, p._best_moves_label.text], ["8", "10", "7"])
	eq(p._subtitle.text, "LEVEL 24 CLEARED")
	eq([p._from_label.text, p._to_label.text], ["LEVEL 24", "LEVEL 25"])
	p.show_result(5, 1, true, -1, false, false, true, -1, 24)
	p.skip_presentation()
	eq([p._target_label.text, p._best_moves_label.text], ["--", "--"])
	p.queue_free()


func test_stat_label_reads_par() -> void:
	var p := await _popup()
	var found := false
	for l in p.find_children("*", "Label", true, false):
		ok(l.text != "TARGET", "no visible TARGET label")
		if l.text == "PAR":
			found = true
	ok(found, "PAR label present")
	p.queue_free()


func test_final_level_and_hidden_progress() -> void:
	var p := await _popup()
	p.show_result(5, 3, false, -1, false, false, true, 5, 4000)
	p.skip_presentation()
	eq(p._from_label.text, "LEVEL 4000 COMPLETE")
	eq(p._subtitle.text, "LEVEL 4000 CLEARED")
	ok(p._to_label.text != "LEVEL 4001" or not p._to_label.visible, "N+1 never shown on the final level")
	ok(not p._to_label.visible and not p._arrow_label.visible and not p._next_button.visible)
	p.show_result(5, 3, true, -1, false, false, true, 5, -1)
	ok(not p._progress_row.visible and not p._subtitle.visible, "no level number => no subtitle/progress")
	p.show_result(5, 0, true, -1, false, false, false)
	ok(not p._stars_holder.visible and not p._badge_holder.visible, "QA sessions show no stars")
	p.queue_free()


func test_buttons_locked_until_entrance_done() -> void:
	var p := await _popup()
	var nxt := watch(p.next_level_pressed)
	var rty := watch(p.retry_pressed)
	var mnu := watch(p.level_select_pressed)
	p.show_result(8, 3, true, 7, false, false, true, 10, 24)
	ok(p.is_input_locked())
	p._next_button.pressed.emit()
	p._retry_button.pressed.emit()
	p._level_select_button.pressed.emit()
	eq([nxt.size(), rty.size(), mnu.size()], [0, 0, 0], "no relay while locked")
	# the real timeline unlocks on its own in ~2 s
	await runner.get_tree().create_timer(3.0).timeout
	ok(not p.is_input_locked(), "unlocked after the entrance")
	ok(not p._next_button.disabled)
	p._next_button.pressed.emit()
	p._retry_button.pressed.emit()
	p._level_select_button.pressed.emit()
	eq([nxt.size(), rty.size(), mnu.size()], [1, 1, 1], "each action relays exactly once")
	p.queue_free()


func test_skip_and_repeated_show_reset_state() -> void:
	var p := await _popup()
	p.show_result(8, 3, true, 7, false, false, true, 10, 24)
	await runner.get_tree().create_timer(0.5).timeout
	p.show_result(4, 1, true, 3, false, false, true, 4, 25)
	ok(p.is_input_locked())
	eq(p._moves_label.text, "0")
	eq(p._stars[1].scale, Vector2.ONE, "unearned star stays at rest")
	eq(p._stars[0].scale, Vector2.ONE * 0.1, "earned star restarts hidden")
	eq(p._badge_fx.get_child_count() + p._front_fx.get_child_count() + p._back_fx.get_child_count(), 0, "old fx cleared")
	p.skip_presentation()
	eq(p._moves_label.text, "4")
	eq(_earned_count(p), 1)
	for b in [p._next_button, p._retry_button, p._level_select_button]:
		eq(b.scale, Vector2.ONE)
		ok(not b.disabled)
	p.hide()
	await frames(2)
	eq(p._tweens.size(), 0, "hiding stops every tween")
	p.queue_free()


func test_no_qa_controls_in_popup() -> void:
	var p := await _popup()
	for b in p.find_children("*", "BaseButton", true, false):
		ok(String(b.name) in ["NextLevelButton", "RetryButton", "LevelSelectButton"], "unexpected button %s" % b.name)
	p.queue_free()
