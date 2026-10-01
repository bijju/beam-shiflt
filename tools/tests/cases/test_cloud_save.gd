extends TestCase

const FakeBackend := preload("res://tools/tests/fakes/fake_cloud_backend.gd")
const FakeFs := preload("res://tools/tests/fakes/fake_firestore.gd")

var _snap: Dictionary
var _auth_state: Dictionary
var _scene_before: Node


func before_each() -> void:
	_snap = SaveManager.to_dict().duplicate(true)
	_scene_before = runner.get_tree().current_scene
	_auth_state = {"u": FirebaseAuth._uid, "r": FirebaseAuth._refresh_token}


func after_each() -> void:
	SaveManager._apply_data(_snap.duplicate(true))
	runner.get_tree().current_scene = _scene_before
	FirebaseAuth._uid = _auth_state["u"]
	FirebaseAuth._refresh_token = _auth_state["r"]


func _cloud_save() -> Node:
	var cs: Node = load("res://scripts/managers/cloud_save.gd").new()
	runner.add_child(cs)
	return cs


func _install(cs: Node, native: Node, firebase: Node) -> void:
	cs._native_backend = native
	cs._firebase_backend = firebase
	if native != null:
		runner.add_child(native)
	if firebase != null:
		runner.add_child(firebase)


func _profile(play: float, level: int, saved := "2026-01-01T00:00:00") -> Dictionary:
	var d := SaveManager.to_dict().duplicate(true)
	d["play_time_seconds"] = play
	d["procedural_current_level"] = level
	d["saved_at"] = saved
	return d


func test_backend_selection_priority() -> void:
	var cs := _cloud_save()
	var native := FakeBackend.new()
	var fb := FakeBackend.new()
	fb.available = false
	_install(cs, native, fb)
	var changes := watch(cs.signed_in_changed)
	cs._select_backend()
	ok(cs.is_available())
	ok(cs.has_native_backend())
	eq(cs.native_service_name(), "Fake Cloud")
	ok(not cs.is_signed_in, "native not authenticated yet")
	cs._on_native_sign_in_changed(true)
	ok(cs.is_signed_in)
	eq(native.pulls, 1)
	fb.available = true
	cs._select_backend()
	eq(fb.pulls, 1, "firebase wins once signed in")
	for i in 5:
		cs._select_backend()
	eq(fb.pulls, 1, "re-selection is idempotent")
	eq(cs.service_name(), "Fake Cloud")
	cs.sign_in()
	eq(fb.sign_ins, 1)
	eq(cs.last_error(), "")
	fb.available = false
	cs._on_native_sign_in_changed(false)
	ok(not cs.is_signed_in)
	cs._backend = null
	eq(cs.service_name(), "")
	eq(cs.last_error(), "")
	cs.sign_in()
	cs.sync_now()
	ok(changes.size() >= 2)
	cs.queue_free()


func test_no_backends() -> void:
	var cs := _cloud_save()
	cs._native_backend = null
	cs._firebase_backend = null
	cs._select_backend()
	ok(not cs.is_available())
	eq(cs.native_service_name(), "")
	cs.queue_free()


func test_reconcile_policy() -> void:
	var cs := _cloud_save()
	var fb := FakeBackend.new()
	_install(cs, null, fb)
	var chooser := watch(cs.chooser_needed)
	# fresh install: local has no play time, cloud has some -> adopt
	SaveManager.play_time_seconds = 0.0
	cs._on_profile_loaded(_profile(100.0, 12))
	eq(SaveManager.procedural_current_level, 12)
	# empty profile ignored
	cs._on_profile_loaded({})
	# big divergence -> chooser
	SaveManager.play_time_seconds = 50.0
	cs._on_profile_loaded(_profile(50.0 + CloudSave.CHOOSER_THRESHOLD + 10.0, 40))
	eq(chooser.size(), 1)
	ok(cs.has_pending_choice())
	cs.take_cloud()
	eq(SaveManager.procedural_current_level, 40)
	ok(not cs.has_pending_choice())
	# keep local clears and syncs
	cs.pending_cloud = _profile(9999.0, 2)
	cs.pending_local = {}
	cs.keep_local()
	ok(not cs.has_pending_choice())
	# small divergence: cloud with more play time wins; with less loses
	SaveManager.play_time_seconds = 1000.0
	SaveManager.procedural_current_level = 5
	cs._on_profile_loaded(_profile(900.0, 99))
	eq(SaveManager.procedural_current_level, 5)
	cs._on_profile_loaded(_profile(1100.0, 77))
	eq(SaveManager.procedural_current_level, 77)
	# tie on play time -> newer saved_at wins
	SaveManager.play_time_seconds = 1100.0
	SaveManager.saved_at = "2026-01-01T00:00:00"
	cs._on_profile_loaded(_profile(1100.0, 88, "2027-01-01T00:00:00"))
	eq(SaveManager.procedural_current_level, 88)
	eq(CloudSave.play_time_of({}), 0.0)
	eq(CloudSave.level_of({}), 1)
	cs.queue_free()


func test_profile_held_while_in_level() -> void:
	var cs := _cloud_save()
	var fb := FakeBackend.new()
	_install(cs, null, fb)
	var dummy := Node.new()
	dummy.scene_file_path = CloudSave.GAME_SCENE
	runner.get_tree().root.add_child(dummy)
	runner.get_tree().current_scene = dummy
	ok(cs._in_level())
	SaveManager.play_time_seconds = 0.0
	cs._on_profile_loaded(_profile(500.0, 31))
	ok(SaveManager.procedural_current_level != 31, "held, not adopted")
	cs._on_conflict_found([_profile(10.0, 3), _profile(20.0, 4)])
	runner.get_tree().current_scene = _scene_before
	dummy.queue_free()
	cs.reconcile_held()
	cs.reconcile_held()
	cs.queue_free()


func test_conflict_resolution() -> void:
	var cs := _cloud_save()
	var fb := FakeBackend.new()
	_install(cs, null, fb)
	cs._backend = fb
	cs._on_conflict_found([])
	cs._on_conflict_found(["junk", 5])
	eq(fb.resolved.size(), 0)
	cs._on_conflict_found([_profile(10.0, 3), _profile(30.0, 4), _profile(20.0, 5)])
	eq(fb.resolved.size(), 1)
	eq(SaveManager.procedural_current_level, 4)
	cs.queue_free()


func test_push_throttle_and_flush() -> void:
	var cs := _cloud_save()
	var fb := FakeBackend.new()
	_install(cs, null, fb)
	cs._backend = fb
	cs.is_signed_in = true
	var synced := watch(cs.synced)
	cs._process(1.0)  # nothing queued
	cs._on_local_save()
	cs._process(CloudSave.PUSH_COOLDOWN - 1.0)
	eq(fb.pushes.size(), 0)
	cs._process(2.0)
	eq(fb.pushes.size(), 1)
	ok(not fb.pushes[0][0].has("entitlements"), "entitlements never travel")
	cs._on_local_save()
	cs._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	eq(fb.pushes.size(), 2)
	cs._on_push_finished(true)
	ok(cs.last_synced_at != "")
	cs._on_push_finished(false)
	eq(synced.size(), 2)
	cs.is_signed_in = false
	cs._on_local_save()
	ok(not cs._push_queued)
	cs._flush_push()
	cs.queue_free()


func test_real_ready_wires_real_backends() -> void:
	var cs := _cloud_save()
	await frames(2)
	ok(cs._firebase_backend != null)
	cs._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	cs.queue_free()


func test_firebase_backend_contract() -> void:
	var b: Node = load("res://scripts/cloud/firebase_cloud_backend.gd").new()
	runner.add_child(b)
	var fs := FakeFs.new(b)
	fs.scripted = true
	b._firestore = fs
	var loaded := watch(b.profile_loaded)
	var pushed := watch(b.push_finished)
	var signed := watch(b.sign_in_changed)
	eq(b.service_name(), "BeamShift Cloud Account")
	b.sign_in()
	FirebaseAuth._uid = ""
	FirebaseAuth._refresh_token = ""
	ok(not b.is_available())
	b.pull()
	b.push({"a": 1}, 0)
	eq(pushed[0][0], false)
	FirebaseAuth._uid = "uid1"
	FirebaseAuth._refresh_token = "rt"
	ok(b.is_available())
	fs.queue.append([true, {"play_time_seconds": 5.0}, "", 200])
	b.pull()
	eq(loaded.size(), 1)
	fs.queue.append([true, {}, "", 200])
	b.pull()
	eq(loaded.size(), 1, "empty document emits nothing")
	fs.queue.append([false, {}, "NOT_FOUND", 404])
	b.pull()
	eq(b.last_error, "", "not found is not an error")
	for pair in [["OFFLINE", "No internet connection."], ["NO_AUTH", "Not signed in to a BeamShift account."], ["PERMISSION_DENIED", "BeamShift Cloud Account access denied."], ["NETWORK_ERROR", "Could not reach BeamShift Cloud Account."], ["X", "BeamShift Cloud Account sync failed (X)."]]:
		fs.queue.append([false, {}, pair[0], 0])
		b.pull()
		eq(b.last_error, pair[1])
	fs.queue.append([true, {}, "", 200])
	b.push({"a": 1}, 0)
	eq(pushed[1][0], true)
	fs.queue.append([false, {}, "OFFLINE", 0])
	b.resolve_conflict({"a": 2}, 0)
	eq(pushed[2][0], false)
	b._on_auth_state_changed(true)
	eq(signed.size(), 1)
	b.queue_free()
