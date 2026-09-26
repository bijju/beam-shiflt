class_name AdBackendAdMob
extends AdBackend
## Google Mobile Ads through the Poing Studios Godot AdMob plugin (v5.1.0, addons/admob).
## Only instantiated on Android/iOS. Consent (UMP) runs first every launch; the SDK starts
## when UMP answers or after AdConfig.CONSENT_TIMEOUT_SECONDS (UMP can fail to call back
## on some devices). Every ad object is destroyed on dismiss/failure (plugin requirement).
## Ad-unit IDs come from AdConfig only.
##
## Audience: BeamShift's audience includes children, so EVERY request is child-directed
## (TFCD + TFUA, max rating G) - non-personalised ads only, no consent form, no IDFA/ATT.
## See ADS_MONETIZATION.md "Child-directed configuration" before changing this.
##
## Every callback handed to the plugin is a NAMED method, never a lambda: the plugin keeps
## some in static slots that Godot 4.7 clears only after this script is freed, and a late-
## destroyed lambda reads freed memory and aborts iOS on swipe-away. release() empties
## those slots while this object is still alive (AdManager calls it from _exit_tree).

var _rewarded: RewardedAd
var _interstitial: InterstitialAd
var _loading_rewarded := false
var _loading_interstitial := false
var _sdk_started := false
var _consent_known := false
var _consent_form: ConsentForm
var _privacy_done: Callable = Callable()
var _released := false


func initialize() -> void:
	var params := ConsentRequestParameters.new()
	params.tag_for_under_age_of_consent = AdConfig.CHILD_DIRECTED
	UserMessagingPlatform.consent_information.update(params, _on_consent_updated, _on_consent_update_failed)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.create_timer(AdConfig.CONSENT_TIMEOUT_SECONDS, true, false, true).timeout.connect(_on_consent_timeout)


func _on_consent_updated() -> void:
	_consent_known = true
	if UserMessagingPlatform.consent_information.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(_on_form_loaded, _on_form_failed)
	else:
		_init_sdk()


func _on_consent_update_failed(_error: FormError) -> void:
	_init_sdk() # _init_sdk() still refuses when consent is known to be REQUIRED


func _on_consent_timeout() -> void:
	if not _consent_known:
		_init_sdk()


func _on_form_loaded(form: ConsentForm) -> void:
	_consent_form = form
	if UserMessagingPlatform.consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		form.show(_on_form_dismissed)
	else:
		_init_sdk()


func _on_form_failed(_error: FormError) -> void:
	_init_sdk()


func _on_form_dismissed(_error: FormError) -> void:
	_consent_form = null
	_init_sdk()


func _init_sdk() -> void:
	if _sdk_started or _released:
		return
	if UserMessagingPlatform.consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		initialized.emit(false) # consent still required (form dismissed unanswered): no ads
		return
	_sdk_started = true
	var config := RequestConfiguration.new()
	if AdConfig.CHILD_DIRECTED:
		config.tag_for_child_directed_treatment = RequestConfiguration.TagForChildDirectedTreatment.TRUE
		config.tag_for_under_age_of_consent = RequestConfiguration.TagForUnderAgeOfConsent.TRUE
		config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	for id in AdConfig.test_device_ids():
		config.test_device_ids.append(id)
	MobileAds.set_request_configuration(config)
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = _on_initialization_complete
	MobileAds.initialize(listener)


func _on_initialization_complete(_status: InitializationStatus) -> void:
	initialized.emit(true)


# --- Rewarded ---------------------------------------------------------------------------

func load_rewarded() -> void:
	if _loading_rewarded or _rewarded != null or _released:
		return
	_loading_rewarded = true
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = _on_rewarded_loaded
	cb.on_ad_failed_to_load = _on_rewarded_failed_to_load
	RewardedAdLoader.new().load(AdConfig.unit_id("rewarded"), AdRequest.new(), cb)


func _on_rewarded_loaded(ad: RewardedAd) -> void:
	_loading_rewarded = false
	_rewarded = ad
	var fs := FullScreenContentCallback.new()
	fs.on_ad_showed_full_screen_content = _on_rewarded_showed
	fs.on_ad_dismissed_full_screen_content = _on_rewarded_dismissed
	fs.on_ad_failed_to_show_full_screen_content = _on_rewarded_failed_to_show
	ad.full_screen_content_callback = fs
	rewarded_loaded.emit()


func _on_rewarded_failed_to_load(e: LoadAdError) -> void:
	_loading_rewarded = false
	rewarded_load_failed.emit(e.message)


func _on_rewarded_showed() -> void:
	rewarded_opened.emit()


func _on_rewarded_dismissed() -> void:
	_destroy_rewarded()
	rewarded_closed.emit()


func _on_rewarded_failed_to_show(e: AdError) -> void:
	_destroy_rewarded()
	rewarded_show_failed.emit(e.message)


func _on_user_earned_reward(_item: RewardedItem) -> void:
	reward_earned.emit()


func has_rewarded() -> bool:
	return _rewarded != null


func show_rewarded() -> bool:
	if _rewarded == null:
		return false
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = _on_user_earned_reward
	_rewarded.show(listener)
	return true


func _destroy_rewarded() -> void:
	if _rewarded:
		_rewarded.destroy()
		_rewarded = null


# --- Interstitial -----------------------------------------------------------------------

func load_interstitial() -> void:
	if _loading_interstitial or _interstitial != null or _released:
		return
	_loading_interstitial = true
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = _on_interstitial_loaded
	cb.on_ad_failed_to_load = _on_interstitial_failed_to_load
	InterstitialAdLoader.new().load(AdConfig.unit_id("interstitial"), AdRequest.new(), cb)


func _on_interstitial_loaded(ad: InterstitialAd) -> void:
	_loading_interstitial = false
	_interstitial = ad
	var fs := FullScreenContentCallback.new()
	fs.on_ad_showed_full_screen_content = _on_interstitial_showed
	fs.on_ad_dismissed_full_screen_content = _on_interstitial_dismissed
	fs.on_ad_failed_to_show_full_screen_content = _on_interstitial_failed_to_show
	ad.full_screen_content_callback = fs
	interstitial_loaded.emit()


func _on_interstitial_failed_to_load(e: LoadAdError) -> void:
	_loading_interstitial = false
	interstitial_load_failed.emit(e.message)


func _on_interstitial_showed() -> void:
	interstitial_opened.emit()


func _on_interstitial_dismissed() -> void:
	_destroy_interstitial()
	interstitial_closed.emit()


func _on_interstitial_failed_to_show(e: AdError) -> void:
	_destroy_interstitial()
	interstitial_show_failed.emit(e.message)


func has_interstitial() -> bool:
	return _interstitial != null


func show_interstitial() -> bool:
	if _interstitial == null:
		return false
	_interstitial.show()
	return true


func _destroy_interstitial() -> void:
	if _interstitial:
		_interstitial.destroy()
		_interstitial = null


## Drops a loaded interstitial (the player bought No Forced Ads).
func discard_interstitial() -> void:
	_destroy_interstitial()


# --- Privacy options (UMP) ----------------------------------------------------------------

## Only meaningful once UMP has answered; with child-directed tagging it is normally
## NOT_REQUIRED, so the Settings button stays hidden.
func privacy_options_required() -> bool:
	if not _consent_known:
		return false
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func show_privacy_options(on_done: Callable) -> void:
	_privacy_done = on_done
	UserMessagingPlatform.show_privacy_options_form(_on_privacy_options_dismissed)


func _on_privacy_options_dismissed(_error: FormError) -> void:
	# The new choice applies to the next request: drop ads loaded under the old one.
	_destroy_rewarded()
	_destroy_interstitial()
	var cb := _privacy_done
	_privacy_done = Callable()
	if cb.is_valid():
		cb.call()


# --- Teardown -----------------------------------------------------------------------------

func release() -> void:
	if _released:
		return
	_released = true
	_destroy_rewarded()
	_destroy_interstitial()
	_consent_form = null
	_privacy_done = Callable()
	for plugin in [MobileAds._plugin, UserMessagingPlatform._plugin, ConsentInformation._plugin, InterstitialAd._plugin, RewardedAd._plugin]:
		_disconnect_all(plugin)
	MobileAds._current_on_initialization_complete_listener = null
	MobileAds._current_on_ad_inspector_closed_listener = null
	UserMessagingPlatform.active_consent_form = null
	UserMessagingPlatform._on_consent_form_load_success_listener_callback = null
	UserMessagingPlatform._on_consent_form_load_failure_listener_callback = null
	UserMessagingPlatform._on_privacy_options_form_dismissed_callback = null
	var information := UserMessagingPlatform.consent_information
	if information != null:
		information._on_consent_info_updated_success_callback = null
		information._on_consent_info_updated_failure_callback = null


## Only the plugin's own signals: the ones every Node carries hold engine wiring, not ours.
static func _disconnect_all(plugin: Object) -> void:
	if plugin == null:
		return
	for sig in plugin.get_signal_list():
		if ClassDB.class_has_signal("Node", sig.name):
			continue
		for connection in plugin.get_signal_connection_list(sig.name):
			plugin.disconnect(sig.name, connection.callable)
