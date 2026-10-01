extends TestCase

var _snap: Dictionary
var _online: bool


func before_each() -> void:
	_snap = SaveManager.to_dict().duplicate(true)
	_online = InternetManager.is_online
	InternetManager.is_online = true


func after_each() -> void:
	SaveManager._apply_data(_snap.duplicate(true))
	InternetManager.is_online = _online


func _manager() -> Node:
	var am: Node = load("res://scripts/managers/ad_manager.gd").new()
	runner.add_child(am)
	var fake := AdBackendFake.new()
	am.use_backend(fake)
	return am


func test_ad_config() -> void:
	ok(AdConfig.platform() in ["", "android", "ios"])
	eq(AdConfig.unit_id("rewarded", ""), "")
	ok(AdConfig.unit_id("rewarded", "android") != "" or not AdConfig.USE_TEST_IDS)
	ok(AdConfig.unit_id("bogus", "android") == "")
	AdConfig.config_problem("android")
	AdConfig.ads_active("android")
	AdConfig.production_ids()
	AdConfig.test_device_ids()
	ok(AdConfig.TEST_IDS.has("ios"))


func test_base_backend_defaults() -> void:
	var b := AdBackend.new()
	var got := []
	b.initialized.connect(func(v: bool) -> void: got.append(v))
	b.rewarded_load_failed.connect(func(_m: String) -> void: got.append("rl"))
	b.interstitial_load_failed.connect(func(_m: String) -> void: got.append("il"))
	b.initialize()
	b.load_rewarded()
	b.load_interstitial()
	eq(got, [false, "rl", "il"])
	ok(not b.has_rewarded())
	ok(not b.show_rewarded())
	ok(not b.has_interstitial())
	ok(not b.show_interstitial())
	ok(not b.privacy_options_required())
	b.show_privacy_options(Callable())
	b.discard_interstitial()
	b.release()


func test_fake_backend() -> void:
	var f := AdBackendFake.new()
	f.initialize()
	f.load_rewarded()
	f.load_rewarded()
	ok(f.has_rewarded())
	for mode in ["reward", "close_no_reward", "fail"]:
		f.show_mode = mode
		f.load_rewarded()
		ok(f.show_rewarded())
	ok(not f.show_rewarded())
	f.load_interstitial()
	f.load_interstitial()
	ok(f.has_interstitial())
	f.discard_interstitial()
	ok(not f.has_interstitial())
	ok(not f.show_interstitial())
	f.load_interstitial()
	f.show_mode = "fail"
	ok(f.show_interstitial())
	f.show_mode = "reward"
	f.load_interstitial()
	ok(f.show_interstitial())
	f.load_ok = false
	f.load_rewarded()
	f.load_interstitial()
	await frames(2)


func test_rewarded_flow_success() -> void:
	var am := _manager()
	ok(am.is_supported())
	ok(am.hint_requires_ad())
	var res := []
	eq(am.show_rewarded_hint(func(g: bool) -> void: res.append(g)), "not_ready")
	am.initialize_ads()
	await frames(3)
	ok(am.is_rewarded_ready())
	eq(am.show_rewarded_hint(func(g: bool) -> void: res.append(g)), "started")
	ok(am.is_showing())
	eq(am.show_rewarded_hint(Callable()), "busy")
	await frames(3)
	eq(res, [true])
	ok(not am.is_showing())
	am.queue_free()


func test_rewarded_flow_no_reward_and_fail() -> void:
	var am := _manager()
	var fake: AdBackendFake = am._backend
	am.initialize_ads()
	await frames(3)
	fake.show_mode = "close_no_reward"
	var res := []
	am.show_rewarded_hint(func(g: bool) -> void: res.append(g))
	await frames(3)
	eq(res, [false])
	await frames(2)
	fake.show_mode = "fail"
	am.show_rewarded_hint(func(g: bool) -> void: res.append(g))
	await frames(3)
	eq(res, [false, false])
	# stray reward callbacks are ignored
	am._on_reward_earned()
	am._on_rewarded_opened()
	fake.load_ok = false
	am._rewarded_ready = false
	am.load_rewarded()
	await frames(2)
	am.queue_free()


func test_offline_load_is_skipped() -> void:
	var am := _manager()
	am.initialize_ads()
	await frames(2)
	InternetManager.is_online = false
	am._rewarded_ready = false
	am._interstitial_ready = false
	am.load_rewarded()
	am.load_interstitial()
	am.queue_free()


func test_interstitial_rules() -> void:
	var am := _manager()
	var t := [1000]
	am.time_source = func() -> int: return t[0]
	am.initialize_ads()
	await frames(3)
	SaveManager.ad_completions_since_interstitial = 0
	SaveManager.ad_last_interstitial_unix = 0
	SaveManager.ad_last_counted_level = 0
	eq(am.register_completion(5), 1)
	eq(am.register_completion(5), 1, "same level never double counts")
	ok(not am.is_interstitial_due())
	ok(not am.maybe_show_interstitial_after_completion(false, Callable()))
	am.register_completion(6)
	am.register_completion(7)
	am.register_completion(8)
	ok(am.is_interstitial_due())
	ok(not am.maybe_show_interstitial_after_completion(true, Callable()), "suppressed")
	var done := []
	ok(am.maybe_show_interstitial_after_completion(false, func() -> void: done.append(1)))
	ok(am.maybe_show_interstitial_after_completion(false, Callable()), "swallowed while showing")
	await frames(3)
	eq(done, [1])
	eq(SaveManager.ad_completions_since_interstitial, 0)
	for i in range(10, 14):
		am.register_completion(i)
	ok(not am.is_interstitial_due(), "cooldown")
	t[0] += 500
	ok(am.is_interstitial_due())
	# not ready -> never blocks
	am._interstitial_ready = false
	ok(not am.maybe_show_interstitial_after_completion(false, Callable()))
	# show failure path
	await frames(2)
	var fake: AdBackendFake = am._backend
	fake.show_mode = "fail"
	fake.load_interstitial()
	am._interstitial_ready = true
	am.maybe_show_interstitial_after_completion(false, func() -> void: done.append(2))
	await frames(3)
	ok(done.has(2))
	# entitlement removes interstitials
	SaveManager.set_entitlement(StoreConfig.NO_FORCED_ADS, true)
	ok(am.forced_ads_removed())
	ok(not am.maybe_show_interstitial_after_completion(false, Callable()))
	am.load_interstitial()
	am.on_forced_ads_removed()
	ok(not am.show_interstitial(Callable()))
	am.queue_free()


func test_privacy_and_retry() -> void:
	var am := _manager()
	ok(not am.is_privacy_options_required())
	am.show_privacy_options()
	am.show_privacy_options(func() -> void: pass)
	am._on_rewarded_load_failed("x")
	am._on_rewarded_load_failed("x")
	am._on_interstitial_load_failed("x")
	am._on_interstitial_show_failed("x")
	am._on_rewarded_show_failed("x")
	am._on_initialized(false)
	ok(not am.is_rewarded_ready())
	ok(not am.is_interstitial_ready())
	am.queue_free()
	var bare: Node = load("res://scripts/managers/ad_manager.gd").new()
	ok(not bare.is_supported())
	ok(not bare.is_privacy_options_required())
	bare.show_privacy_options()
	bare.initialize_ads()
	bare.on_forced_ads_removed()
	bare.free()
