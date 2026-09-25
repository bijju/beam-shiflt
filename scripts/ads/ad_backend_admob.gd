class_name AdBackendAdMob
extends AdBackend
## Google Mobile Ads through the Poing Studios Godot AdMob plugin (v5.1.0, addons/admob).
## Only instantiated on Android/iOS. Consent (UMP) runs first every launch; ads are
## requested only when consent is not still REQUIRED. Every ad object is destroyed on
## dismiss/failure (plugin requirement). Ad-unit IDs come from AdConfig only.

var _rewarded: RewardedAd
var _interstitial: InterstitialAd
var _loading_rewarded := false
var _loading_interstitial := false


func initialize() -> void:
	var params := ConsentRequestParameters.new()
	UserMessagingPlatform.consent_information.update(params, _on_consent_updated, _on_consent_update_failed)


func _on_consent_updated() -> void:
	if UserMessagingPlatform.consent_information.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(_on_form_loaded, func(_e: FormError) -> void: _init_sdk())
	else:
		_init_sdk()


func _on_consent_update_failed(_error: FormError) -> void:
	_init_sdk() # _init_sdk() still refuses when consent is known to be REQUIRED


func _on_form_loaded(form: ConsentForm) -> void:
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	if status == ConsentInformation.ConsentStatus.REQUIRED:
		form.show(func(_e: FormError) -> void: _init_sdk())
	else:
		_init_sdk()


func _init_sdk() -> void:
	if UserMessagingPlatform.consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		initialized.emit(false) # consent still required (form dismissed unanswered): no ads
		return
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_s: InitializationStatus) -> void: initialized.emit(true)
	MobileAds.set_request_configuration(RequestConfiguration.new())
	MobileAds.initialize(listener)


# --- Rewarded ---------------------------------------------------------------------------

func load_rewarded() -> void:
	if _loading_rewarded or _rewarded != null:
		return
	_loading_rewarded = true
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		_loading_rewarded = false
		_rewarded = ad
		var fs := FullScreenContentCallback.new()
		fs.on_ad_showed_full_screen_content = func() -> void: rewarded_opened.emit()
		fs.on_ad_dismissed_full_screen_content = func() -> void:
			_destroy_rewarded()
			rewarded_closed.emit()
		fs.on_ad_failed_to_show_full_screen_content = func(e: AdError) -> void:
			_destroy_rewarded()
			rewarded_show_failed.emit(e.message)
		ad.full_screen_content_callback = fs
		rewarded_loaded.emit()
	cb.on_ad_failed_to_load = func(e: LoadAdError) -> void:
		_loading_rewarded = false
		rewarded_load_failed.emit(e.message)
	RewardedAdLoader.new().load(AdConfig.unit_id("rewarded"), AdRequest.new(), cb)


func has_rewarded() -> bool:
	return _rewarded != null


func show_rewarded() -> bool:
	if _rewarded == null:
		return false
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void: reward_earned.emit()
	_rewarded.show(listener)
	return true


func _destroy_rewarded() -> void:
	if _rewarded:
		_rewarded.destroy()
		_rewarded = null


# --- Interstitial -----------------------------------------------------------------------

func load_interstitial() -> void:
	if _loading_interstitial or _interstitial != null:
		return
	_loading_interstitial = true
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_loading_interstitial = false
		_interstitial = ad
		var fs := FullScreenContentCallback.new()
		fs.on_ad_showed_full_screen_content = func() -> void: interstitial_opened.emit()
		fs.on_ad_dismissed_full_screen_content = func() -> void:
			_destroy_interstitial()
			interstitial_closed.emit()
		fs.on_ad_failed_to_show_full_screen_content = func(e: AdError) -> void:
			_destroy_interstitial()
			interstitial_show_failed.emit(e.message)
		ad.full_screen_content_callback = fs
		interstitial_loaded.emit()
	cb.on_ad_failed_to_load = func(e: LoadAdError) -> void:
		_loading_interstitial = false
		interstitial_load_failed.emit(e.message)
	InterstitialAdLoader.new().load(AdConfig.unit_id("interstitial"), AdRequest.new(), cb)


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


# --- Privacy options (UMP) - for a future Settings entry ---------------------------------

func privacy_options_required() -> bool:
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func show_privacy_options(on_done: Callable) -> void:
	UserMessagingPlatform.show_privacy_options_form(func(_e: FormError) -> void: on_done.call())
