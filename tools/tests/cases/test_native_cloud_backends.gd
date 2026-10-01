extends TestCase
## Game Center and Play Games cloud backends, driven through duck-typed fakes
## (the real platform objects only exist on a device).

const Fake := preload("res://tools/tests/fakes/fake_game_center.gd")


func _gc() -> Node:
	var b: Node = load("res://scripts/cloud/game_center_cloud_backend.gd").new()
	runner.add_child(b)
	return b


func _profile_game(profile: Dictionary) -> Object:
	var g := Fake.FakeGame.new()
	g.payload = JSON.stringify(profile).to_utf8_buffer()
	return g


func test_game_center_sign_in_and_push() -> void:
	var b := _gc()
	ok(not b.is_available(), "no extension on desktop")
	eq(b.service_name(), "Game Center")
	b.sign_in()
	b.pull()
	var pushed := watch(b.push_finished)
	b.push({"a": 1}, 0)
	eq(pushed[0][0], false)
	b.resolve_conflict({}, 0)
	var mgr := Fake.FakeManager.new()
	var player := Fake.FakePlayer.new()
	mgr.local_player = player
	b._manager = mgr
	mgr.authentication_result.connect(b._on_authenticated)
	mgr.authentication_error.connect(b._on_auth_error)
	ok(b.is_available())
	var signed := watch(b.sign_in_changed)
	b.sign_in()
	eq(mgr.authenticate_calls, 1)
	mgr.authentication_result.emit(true)
	ok(b._signed_in)
	ok(player.listener_registered)
	b.sign_in()  # already signed in
	eq(mgr.authenticate_calls, 1)
	b.push({"a": 1}, 5)
	eq(pushed[1][0], true)
	player.save_error = Fake.FakeError.new()
	b.push({"a": 1}, 5)
	eq(pushed[2][0], false)
	ok(b.last_error.contains("GKErrorDomain"))
	mgr.authentication_error.emit("denied")
	ok(not b._signed_in)
	ok(b.last_error.contains("denied"))
	eq(signed.size(), 2)
	b.queue_free()


func test_game_center_no_local_player_and_error_text() -> void:
	var b := _gc()
	var mgr := Fake.FakeManager.new()
	b._manager = mgr
	var signed := watch(b.sign_in_changed)
	b._on_authenticated(true)
	ok(b.last_error.contains("no local player"))
	b._on_authenticated(false)
	eq(signed.size(), 2)
	ok(b._error_text(null).contains("unexpected"))
	ok(b._error_text(5).contains("unexpected"))
	var e := Fake.FakeError.new()
	ok(b._error_text(e).contains("boom"))
	e.code = 9999
	e.message = ""
	ok(b._error_text(e).contains("unmapped"))
	b.queue_free()


func test_game_center_fetch_and_conflicts() -> void:
	var b := _gc()
	var player := Fake.FakePlayer.new()
	b._player = player
	var loaded := watch(b.profile_loaded)
	var conflict := watch(b.conflict_found)
	b._fetch()
	player.games = [_profile_game({"play_time_seconds": 5.0}), Fake.FakeGame.new()]
	var other := Fake.FakeGame.new()
	other.name = "someone_elses"
	player.games.append(other)
	b._fetch()
	b._on_fetched(player.games, null)
	ok(loaded.size() >= 1)
	b._on_fetched([_profile_game({"x": 1})], null)
	ok(loaded.size() >= 1)
	b._on_fetched([], null)
	b._on_fetched("not an array", null)
	b._on_fetched(null, Fake.FakeError.new())
	ok(b.last_error != "")
	b._on_fetched([other], null)
	# two profiles -> a conflict
	b._on_fetched([_profile_game({"a": 1}), _profile_game({"a": 2})], null)
	ok(conflict.size() >= 1)
	var winner_calls := player.resolved.size()
	b.resolve_conflict({"a": 2}, 0)
	eq(player.resolved.size(), winner_calls + 1)
	b.resolve_conflict({"a": 2}, 0)  # nothing pending now
	player.resolve_error = Fake.FakeError.new()
	b._conflicts = [_profile_game({})]
	b.resolve_conflict({"a": 2}, 0)
	# listener-driven conflicts
	b._on_conflicting(null, "nope")
	b._on_conflicting(null, [_profile_game({"a": 1})])
	b._on_conflicting(null, [_profile_game({"a": 1}), _profile_game({"a": 2})])
	ok(conflict.size() >= 2)
	var bad := Fake.FakeGame.new()
	bad.payload = "{not json".to_utf8_buffer()
	b._on_conflicting(null, [bad, _profile_game({"a": 1})])
	var errored := Fake.FakeGame.new()
	errored.error = Fake.FakeError.new()
	b._on_conflicting(null, [errored, _profile_game({"a": 1})])
	b._on_fetched([bad], null)
	b._ours([null, other])
	b.queue_free()


func test_game_center_pull_timing() -> void:
	var b := _gc()
	var player := Fake.FakePlayer.new()
	player.games = [_profile_game({"play_time_seconds": 3.0})]
	b._player = player
	var loaded := watch(b.profile_loaded)
	Engine.time_scale = 40.0
	b.pull()  # first pull waits for the settle delay
	var t0 := Time.get_ticks_msec()
	while loaded.is_empty() and Time.get_ticks_msec() - t0 < 4000:
		await frames(1)
	Engine.time_scale = 1.0
	eq(loaded.size(), 1)
	b.pull()  # later pulls fetch immediately
	eq(loaded.size(), 2)
	b.queue_free()


func test_play_games_backend() -> void:
	var b: Node = load("res://scripts/cloud/play_games_cloud_backend.gd").new()
	runner.add_child(b)
	ok(not b.is_available())
	eq(b.service_name(), "Google Play Games")
	b.sign_in()
	b.pull()
	b.push({"a": 1}, 0)
	b.resolve_conflict({"a": 1}, 0)
	var signed := watch(b.sign_in_changed)
	var loaded := watch(b.profile_loaded)
	var pushed := watch(b.push_finished)
	var conflicts := watch(b.conflict_found)
	b._on_user_authenticated(true)
	eq(signed[0][0], true)
	var snap := PlayGamesSnapshot.new({"content": JSON.stringify({"play_time_seconds": 2.0}).to_utf8_buffer()})
	b._on_game_loaded(snap)
	eq(loaded.size(), 1)
	b._on_game_loaded(PlayGamesSnapshot.new({}))
	b._on_game_loaded(null)
	b._on_game_loaded(PlayGamesSnapshot.new({"content": "[1]".to_utf8_buffer()}))
	eq(loaded.size(), 1)
	b._on_game_saved(true, "n", "d")
	eq(b.last_error, "")
	b._on_game_saved(false, "n", "d")
	ok(b.last_error != "")
	eq(pushed.size(), 2)
	var conflict := PlayGamesSnapshotConflict.new({
		"conflictingSnapshot": {"content": JSON.stringify({"a": 1}).to_utf8_buffer()},
		"serverSnapshot": {"content": JSON.stringify({"a": 2}).to_utf8_buffer()},
	})
	b._on_conflict_emitted(conflict)
	eq(conflicts[0][0].size(), 2)
	b._on_conflict_emitted(PlayGamesSnapshotConflict.new({"conflictingSnapshot": {}, "serverSnapshot": {}}))
	eq(conflicts.size(), 1)
	b.queue_free()
