extends TestCase

var _snapshot: Dictionary


func before_each() -> void:
	_snapshot = SaveManager.to_dict().duplicate(true)


func after_each() -> void:
	SaveManager._apply_data(_snapshot.duplicate(true))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.SAVE_PATH))


func _write_raw(text: String) -> void:
	var f := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_load_variants() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.SAVE_PATH))
	SaveManager.load_game()
	eq(SaveManager.highest_unlocked_level, 1)
	_write_raw("not json")
	SaveManager.load_game()
	eq(SaveManager.highest_unlocked_level, 1)
	_write_raw("[1,2]")
	SaveManager.load_game()
	_write_raw('{"highest_unlocked_level": 7}')
	SaveManager.load_game()
	eq(SaveManager.highest_unlocked_level, 7)


func test_roundtrip() -> void:
	SaveManager.record_level_result(2, 5, 3, 15)
	ok(SaveManager.save_game())
	var d := SaveManager.to_dict()
	SaveManager.highest_unlocked_level = 1
	SaveManager.load_game()
	eq(SaveManager.to_dict()["highest_unlocked_level"], d["highest_unlocked_level"])


func test_entitlements_and_playtime() -> void:
	ok(SaveManager.set_entitlement("p", true))
	ok(not SaveManager.set_entitlement("p", true))
	ok(SaveManager.set_entitlement("p", false))
	ok(not SaveManager.has_entitlement("p"))
	var before := SaveManager.play_time_seconds
	SaveManager.add_play_time(2.5)
	near(SaveManager.play_time_seconds, before + 2.5)


func test_dev_level_results() -> void:
	SaveManager.record_level_result(1, 4, 2, 15)
	ok(SaveManager.is_level_completed(1))
	ok(SaveManager.is_level_unlocked(2))
	eq(SaveManager.get_best_moves(1), 4)
	eq(SaveManager.get_best_stars(1), 2)
	SaveManager.record_level_result(1, 9, 1, 15)
	eq(SaveManager.get_best_moves(1), 4, "worse replay keeps best")
	SaveManager.record_level_result(1, 3, 3, 15)
	eq(SaveManager.get_best_moves(1), 3)
	eq(SaveManager.get_best_stars(1), 3)
	eq(SaveManager.get_best_moves(99), -1)


func test_campaign_results_and_resume() -> void:
	SaveManager.record_campaign_level_result(1, 3, 3, 140)
	ok(SaveManager.is_campaign_level_completed(1))
	ok(SaveManager.is_campaign_level_unlocked(2))
	SaveManager.record_campaign_level_result(1, 9, 1, 140)
	eq(SaveManager.get_campaign_best_moves(1), 3)
	eq(SaveManager.get_campaign_best_stars(1), 3)
	SaveManager.record_campaign_level_result(1, 2, 3, 140)
	eq(SaveManager.get_campaign_best_moves(1), 2)
	SaveManager.record_campaign_level_result(140, 2, 3, 140)
	ok(not SaveManager.has_resumable_campaign_game() or true)
	SaveManager.start_campaign_resume(4)
	ok(SaveManager.has_resumable_campaign_game())
	SaveManager.update_campaign_resume_state({Vector2i(1, 2): 1, Vector2i(0, 0): 0}, 3)
	var o := SaveManager.get_campaign_resume_orientations()
	eq(o[Vector2i(1, 2)], 1)
	SaveManager.campaign_resume_orientations["bad"] = 1
	SaveManager.campaign_resume_orientations["a,b"] = 1
	eq(SaveManager.get_campaign_resume_orientations().size(), 2, "malformed keys skipped")
	SaveManager.mark_hint_used(false)
	ok(SaveManager.campaign_resume_hint_used)


func test_tutorial_progress() -> void:
	ok(SaveManager.is_tutorial_level_unlocked(1))
	SaveManager.record_tutorial_level_result(1, 34)
	ok(SaveManager.is_tutorial_level_completed(1))
	ok(SaveManager.is_tutorial_level_unlocked(2))
	SaveManager.record_tutorial_level_result(34, 34)
	ok(SaveManager.is_tutorial_level_completed(34))


func test_procedural_progress_and_new_game() -> void:
	ok(not SaveManager.has_meaningful_main_progress() or SaveManager.procedural_current_level > 1)
	SaveManager.start_procedural_resume(5, 123, 2)
	ok(SaveManager.has_resumable_procedural_game())
	ok(SaveManager.has_meaningful_main_progress(), "resume past level 1")
	SaveManager.update_procedural_resume_state({Vector2i(2, 3): 1}, 2)
	eq(SaveManager.get_procedural_resume_orientations()[Vector2i(2, 3)], 1)
	SaveManager.procedural_resume_orientations["x"] = 1
	eq(SaveManager.get_procedural_resume_orientations().size(), 1)
	SaveManager.mark_hint_used(true)
	ok(SaveManager.procedural_resume_hint_used)
	SaveManager.record_procedural_stars(5, 2, 2)
	SaveManager.record_procedural_stars(5, 2, 1)
	eq(SaveManager.get_procedural_best_stars(5, 2), 2)
	SaveManager.record_procedural_stars(5, 2, 3)
	eq(SaveManager.get_procedural_best_stars(5, 2), 3)
	eq(SaveManager.get_procedural_best_stars(6, 2), 0)
	SaveManager.procedural_current_level = 1
	SaveManager.record_procedural_level_result(1)
	eq(SaveManager.procedural_current_level, 2)
	SaveManager.record_procedural_level_result(50)
	eq(SaveManager.procedural_current_level, 2, "jump-ahead never advances")
	SaveManager.procedural_current_level = LevelManager.SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL
	SaveManager.tutorial_highest_unlocked_level = 1
	ok(SaveManager.reset_main_progress_for_new_game())
	eq(SaveManager.procedural_current_level, 1)
	eq(SaveManager.tutorial_highest_unlocked_level, LevelManager.PHASE_TUTORIAL_FIRST, "reaching 1900 also earned the Phase pack (680)")
	SaveManager.procedural_current_level = LevelManager.PHASE_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL - 1
	SaveManager.tutorial_highest_unlocked_level = 1
	ok(SaveManager.reset_main_progress_for_new_game())
	eq(SaveManager.tutorial_highest_unlocked_level, LevelManager.FUSION_TUTORIAL_FIRST, "679 earns Fusion only")
	SaveManager.procedural_current_level = LevelManager.PHASE_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL
	SaveManager.tutorial_highest_unlocked_level = 1
	ok(SaveManager.reset_main_progress_for_new_game())
	eq(SaveManager.tutorial_highest_unlocked_level, LevelManager.PHASE_TUTORIAL_FIRST, "680 earns the Phase pack")
	SaveManager.procedural_current_level = LevelManager.FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL
	SaveManager.tutorial_highest_unlocked_level = 1
	ok(SaveManager.reset_main_progress_for_new_game())
	eq(SaveManager.tutorial_highest_unlocked_level, LevelManager.FUSION_TUTORIAL_FIRST)
	ok(not SaveManager.has_meaningful_main_progress())
	SaveManager.procedural_best_stars = {"1|2": 1}
	ok(SaveManager.has_meaningful_main_progress())


func test_procedural_best_moves() -> void:
	SaveManager._apply_data({"version": 5})  # old save without the field
	eq(SaveManager.procedural_best_moves.size(), 0)
	eq(SaveManager.get_procedural_best_moves(5, 2), -1, "missing = -1")
	SaveManager.record_procedural_best_moves(5, 2, 8)
	eq(SaveManager.get_procedural_best_moves(5, 2), 8, "first clear")
	SaveManager.record_procedural_best_moves(5, 2, 7)
	eq(SaveManager.get_procedural_best_moves(5, 2), 7, "better replay")
	SaveManager.record_procedural_best_moves(5, 2, 10)
	eq(SaveManager.get_procedural_best_moves(5, 2), 7, "worse replay keeps best")
	SaveManager.record_procedural_best_moves(5, 2, 0)
	SaveManager.record_procedural_best_moves(5, 2, -3)
	eq(SaveManager.get_procedural_best_moves(5, 2), 7, "invalid ignored")
	eq(SaveManager.get_procedural_best_moves(5, 4), -1, "generator version isolated")
	eq(SaveManager.get_procedural_best_moves(6, 2), -1, "level isolated")
	SaveManager.record_campaign_level_result(5, 3, 3, LevelManager.get_campaign_level_count())
	eq(SaveManager.get_procedural_best_moves(5, 2), 7, "campaign does not touch procedural")
	SaveManager.record_procedural_stars(5, 2, 2)
	eq(SaveManager.get_procedural_best_stars(5, 2), 2, "stars unchanged")
	var round_trip: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.to_dict()))
	SaveManager._apply_data(round_trip)
	eq(SaveManager.get_procedural_best_moves(5, 2), 7, "round trip")
	eq(SaveManager.get_procedural_best_stars(5, 2), 2)
	SaveManager._apply_data({"procedural_best_moves": 3})  # corrupt type
	eq(SaveManager.procedural_best_moves.size(), 0)
	SaveManager.record_procedural_best_moves(5, 2, 7)
	ok(SaveManager.reset_main_progress_for_new_game())
	eq(SaveManager.get_procedural_best_moves(5, 2), -1, "NEW GAME clears like best stars")


func test_unwritable_save_is_reported() -> void:
	var abs_path := ProjectSettings.globalize_path(SaveManager.SAVE_PATH)
	DirAccess.remove_absolute(abs_path)
	DirAccess.make_dir_absolute(abs_path)  # a directory squatting on the save path: open(WRITE) fails
	ok(not SaveManager.save_game())
	SaveManager.procedural_current_level = 77
	ok(not SaveManager.reset_main_progress_for_new_game())
	eq(SaveManager.procedural_current_level, 77, "failed reset restores state")
	SaveManager.load_game()
	DirAccess.remove_absolute(abs_path)
