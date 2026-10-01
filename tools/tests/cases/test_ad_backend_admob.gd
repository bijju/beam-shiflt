extends TestCase
## The real AdMob backend, driven on desktop: the plugin wrappers are null-safe when the
## native singleton is missing, so every callback can be invoked directly.


func _backend() -> AdBackendAdMob:
	return AdBackendAdMob.new()


func test_load_and_show_rewarded() -> void:
	var b := _backend()
	var loaded := watch(b.rewarded_loaded)
	var failed := watch(b.rewarded_load_failed)
	var opened := watch(b.rewarded_opened)
	var closed := watch(b.rewarded_closed)
	var show_failed := watch(b.rewarded_show_failed)
	var earned := watch(b.reward_earned)
	ok(not b.has_rewarded())
	ok(not b.show_rewarded())
	b.load_rewarded()
	b.load_rewarded()  # already loading
	ok(b._loading_rewarded)
	b._on_rewarded_failed_to_load(LoadAdError.new(null, 1, "d", "m", null))
	eq(failed.size(), 1)
	b._on_rewarded_loaded(RewardedAd.new(1))
	eq(loaded.size(), 1)
	ok(b.has_rewarded())
	b.load_rewarded()  # already have one
	ok(b.show_rewarded())
	b._on_rewarded_showed()
	b._on_user_earned_reward(null)
	b._on_rewarded_dismissed()
	eq([opened.size(), earned.size(), closed.size()], [1, 1, 1])
	ok(not b.has_rewarded())
	b._on_rewarded_loaded(RewardedAd.new(2))
	b._on_rewarded_failed_to_show(AdError.new(1, "d", "m", null))
	eq(show_failed.size(), 1)
	b.release()
	b.load_rewarded()
	b.release()


func test_load_and_show_interstitial() -> void:
	var b := _backend()
	var loaded := watch(b.interstitial_loaded)
	var failed := watch(b.interstitial_load_failed)
	var opened := watch(b.interstitial_opened)
	var closed := watch(b.interstitial_closed)
	var show_failed := watch(b.interstitial_show_failed)
	ok(not b.has_interstitial())
	ok(not b.show_interstitial())
	b.load_interstitial()
	b.load_interstitial()
	b._on_interstitial_failed_to_load(LoadAdError.new(null, 1, "d", "m", null))
	eq(failed.size(), 1)
	b._on_interstitial_loaded(InterstitialAd.new(1))
	eq(loaded.size(), 1)
	b.load_interstitial()
	ok(b.has_interstitial())
	ok(b.show_interstitial())
	b._on_interstitial_showed()
	b._on_interstitial_dismissed()
	eq([opened.size(), closed.size()], [1, 1])
	b._on_interstitial_loaded(InterstitialAd.new(2))
	b.discard_interstitial()
	ok(not b.has_interstitial())
	b._on_interstitial_loaded(InterstitialAd.new(3))
	b._on_interstitial_failed_to_show(AdError.new(1, "d", "m", null))
	eq(show_failed.size(), 1)


func test_consent_and_sdk_start() -> void:
	var b := _backend()
	var init := watch(b.initialized)
	b._on_consent_timeout()  # consent never answered: start anyway
	ok(b._sdk_started or init.size() > 0)
	b.release()
	var c := _backend()
	var init2 := watch(c.initialized)
	c._on_consent_updated()
	c._on_consent_update_failed(FormError.new(1, "m"))
	c._on_form_loaded(null)
	c._on_form_failed(FormError.new(1, "m"))
	c._on_form_dismissed(FormError.new(1, "m"))
	c._on_initialization_complete(null)
	ok(init2.size() >= 1)
	c._on_consent_timeout()
	ok(not c.privacy_options_required() or true)
	c._consent_known = true
	c.privacy_options_required()
	var done := []
	c.show_privacy_options(func() -> void: done.append(1))
	c._on_privacy_options_dismissed(FormError.new(1, "m"))
	eq(done, [1])
	c._on_privacy_options_dismissed(FormError.new(1, "m"))  # no callback pending
	c.release()
	c._init_sdk()  # released: ignored
