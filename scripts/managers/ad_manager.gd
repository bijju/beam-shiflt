extends Node
## AdManager - the single game-facing advertising service (5th autoload; earns rule 6
## because ad state - preloaded ads, cooldown, the completion counter, consent - must
## outlive every scene). Full design: ADS_MONETIZATION.md.
##
## Game/HintManager -> AdManager -> AdBackend (AdMob on Android/iOS, fake in tests).
## Gameplay code never calls an SDK. Ads are OPTIONAL services: every failure path
## degrades to "no ad" and never blocks a hint request, a level completion, Next
## Level, saves, generation or audio.
##
## Rewarded hint: the hint is granted ONLY from the reward callback (`reward_earned`).
## Opening, loading, dismissing or failing an ad never grants. No free fallback on
## failure (QA decision): the request simply stays unavailable and a reload is started.
##
## Interstitial: every AdConfig.INTERSTITIAL_EVERY_COMPLETIONS legitimate procedural
## completions AND >= AdConfig.INTERSTITIAL_MIN_SECONDS since the last one, shown only at
## the natural transition (Level Complete -> Next Level). The counter resets ONLY when an
## interstitial is actually shown; not-ready never blocks progression.

signal rewarded_loaded
signal rewarded_failed(message: String)
signal rewarded_opened
signal rewarded_closed
signal reward_earned
signal interstitial_loaded
signal interstitial_failed(message: String)
signal interstitial_opened
signal interstitial_closed

enum State { IDLE, SHOWING_REWARDED, SHOWING_INTERSTITIAL }

var state: State = State.IDLE
## Injectable clock (unix seconds) - tests replace it; production never does.
var time_source: Callable = Callable()

var _backend: AdBackend
var _sdk_ready := false
var _rewarded_ready := false
var _interstitial_ready := false
var _rewarded_retry := 0.0
var _interstitial_retry := 0.0
var _retry_pending := {"rewarded": false, "interstitial": false}
var _hint_callback: Callable = Callable()
var _reward_granted := false
var _interstitial_done: Callable = Callable()
var _muted_before := false


func _ready() -> void:
	if not AdConfig.ADS_ENABLED:
		return
	var problem := AdConfig.config_problem()
	if problem != "":
		push_warning("AdManager: " + problem)
	if AdConfig.platform() == "":
		return # desktop / editor: no ad platform, hints stay free
	use_backend(AdBackendAdMob.new())
	initialize_ads()


## Selects the platform bridge (tests inject a fake).
func use_backend(backend: AdBackend) -> void:
	_backend = backend
	_backend.initialized.connect(_on_initialized)
	_backend.rewarded_loaded.connect(_on_rewarded_loaded)
	_backend.rewarded_load_failed.connect(_on_rewarded_load_failed)
	_backend.rewarded_opened.connect(_on_rewarded_opened)
	_backend.reward_earned.connect(_on_reward_earned)
	_backend.rewarded_closed.connect(_on_rewarded_closed)
	_backend.rewarded_show_failed.connect(_on_rewarded_show_failed)
	_backend.interstitial_loaded.connect(_on_interstitial_loaded)
	_backend.interstitial_load_failed.connect(_on_interstitial_load_failed)
	_backend.interstitial_opened.connect(_on_interstitial_opened)
	_backend.interstitial_closed.connect(_on_interstitial_closed)
	_backend.interstitial_show_failed.connect(_on_interstitial_show_failed)


## Consent (UMP) then SDK init, asynchronously; loads both ad types once ready.
func initialize_ads() -> void:
	if _backend != null:
		_backend.initialize()


func is_supported() -> bool:
	return AdConfig.ADS_ENABLED and _backend != null


## True when a hint request must go through a rewarded ad.
func hint_requires_ad() -> bool:
	return is_supported() and not AdConfig.QA_BYPASS_REWARDED


func is_rewarded_ready() -> bool:
	return _sdk_ready and _rewarded_ready


func is_interstitial_ready() -> bool:
	return _sdk_ready and _interstitial_ready


func is_showing() -> bool:
	return state != State.IDLE


func load_rewarded() -> void:
	if _backend != null and _sdk_ready and not _rewarded_ready:
		_backend.load_rewarded()


func load_interstitial() -> void:
	if _backend != null and _sdk_ready and not _interstitial_ready:
		_backend.load_interstitial()


# --- Rewarded hint ----------------------------------------------------------------------

## Starts the rewarded flow. `on_result(granted: bool)`: true ONLY from the reward
## callback (at most once); false when the ad closed without a reward or failed to show.
## Returns "started", "busy" (another full-screen ad is up / double tap) or "not_ready"
## (a reload was started; the caller keeps the hint unavailable this attempt).
func show_rewarded_hint(on_result: Callable) -> String:
	if state != State.IDLE:
		return "busy"
	if not _sdk_ready or not _rewarded_ready or not _backend.has_rewarded():
		load_rewarded()
		return "not_ready"
	state = State.SHOWING_REWARDED
	_hint_callback = on_result
	_reward_granted = false
	_rewarded_ready = false
	_duck_audio(true)
	if not _backend.show_rewarded():
		_finish_rewarded(false)
		return "not_ready"
	return "started"


func _on_initialized(ok: bool) -> void:
	_sdk_ready = ok
	if ok:
		load_rewarded()
		load_interstitial()


func _on_rewarded_loaded() -> void:
	_rewarded_ready = true
	_rewarded_retry = 0.0
	rewarded_loaded.emit()


func _on_rewarded_load_failed(message: String) -> void:
	_rewarded_ready = false
	rewarded_failed.emit(message)
	_schedule_retry("rewarded")


func _on_rewarded_opened() -> void:
	rewarded_opened.emit()


func _on_reward_earned() -> void:
	if state != State.SHOWING_REWARDED or _reward_granted:
		return # duplicate/stray callback: never a second grant
	_reward_granted = true
	reward_earned.emit()
	var cb := _hint_callback
	_hint_callback = Callable()
	if cb.is_valid():
		cb.call(true)


func _on_rewarded_closed() -> void:
	rewarded_closed.emit()
	_finish_rewarded(_reward_granted)


func _on_rewarded_show_failed(message: String) -> void:
	rewarded_failed.emit(message)
	_finish_rewarded(false)


func _finish_rewarded(granted: bool) -> void:
	if state != State.SHOWING_REWARDED:
		return
	state = State.IDLE
	_duck_audio(false)
	var cb := _hint_callback
	_hint_callback = Callable()
	if cb.is_valid() and not granted:
		cb.call(false)
	load_rewarded() # preload the next one right away


# --- Interstitial: legitimate-completion counter + cooldown ---------------------------------

## Called once per LEGITIMATE completion (normal procedural progression only). Returns
## the new counter. The same level number is never counted twice in a row (a
## Continue-restore of an already-solved board or a Retry of it is not a new completion).
func register_completion(level_number: int) -> int:
	if not AdConfig.ADS_ENABLED:
		return SaveManager.ad_completions_since_interstitial
	if level_number == SaveManager.ad_last_counted_level:
		return SaveManager.ad_completions_since_interstitial
	SaveManager.ad_last_counted_level = level_number
	SaveManager.ad_completions_since_interstitial += 1
	SaveManager.save_game()
	return SaveManager.ad_completions_since_interstitial


func _now() -> int:
	if time_source.is_valid():
		return int(time_source.call())
	return int(Time.get_unix_time_from_system())


## Threshold + cooldown only (readiness/suppression are checked at show time).
func is_interstitial_due() -> bool:
	if SaveManager.ad_completions_since_interstitial < AdConfig.INTERSTITIAL_EVERY_COMPLETIONS:
		return false
	return _now() - SaveManager.ad_last_interstitial_unix >= AdConfig.INTERSTITIAL_MIN_SECONDS


## The natural-transition hook (Level Complete -> Next Level). Returns true when the
## caller must WAIT for `on_done` (an interstitial is showing / one is already up);
## false when nothing was shown and the caller proceeds immediately. `on_done` is called
## exactly once when the ad closes or fails to show. `suppressed` = a rewarded ad was
## watched on this level (no back-to-back full-screen ads; the counter is NOT reset and the
## opportunity moves to the next completion).
func maybe_show_interstitial_after_completion(suppressed: bool, on_done: Callable) -> bool:
	if state == State.SHOWING_INTERSTITIAL:
		return true # second tap on Next while the ad is up: swallow it
	if not is_supported() or state != State.IDLE or suppressed or not is_interstitial_due():
		return false
	if not is_interstitial_ready() or not _backend.has_interstitial():
		load_interstitial() # not ready: never block progression; counter kept (>= threshold)
		return false
	state = State.SHOWING_INTERSTITIAL
	_interstitial_done = on_done
	_interstitial_ready = false
	_duck_audio(true)
	if not _backend.show_interstitial():
		_finish_interstitial(false)
		return false
	return true


func show_interstitial(on_done: Callable) -> bool:
	return maybe_show_interstitial_after_completion(false, on_done)


func _on_interstitial_loaded() -> void:
	_interstitial_ready = true
	_interstitial_retry = 0.0
	interstitial_loaded.emit()


func _on_interstitial_load_failed(message: String) -> void:
	_interstitial_ready = false
	interstitial_failed.emit(message)
	_schedule_retry("interstitial")


func _on_interstitial_opened() -> void:
	interstitial_opened.emit()


func _on_interstitial_closed() -> void:
	interstitial_closed.emit()
	_finish_interstitial(true)


func _on_interstitial_show_failed(message: String) -> void:
	interstitial_failed.emit(message)
	_finish_interstitial(false)


func _finish_interstitial(shown: bool) -> void:
	if state != State.SHOWING_INTERSTITIAL:
		return
	state = State.IDLE
	_duck_audio(false)
	if shown:
		SaveManager.ad_completions_since_interstitial = 0
		SaveManager.ad_last_interstitial_unix = _now()
		SaveManager.save_game()
	var cb := _interstitial_done
	_interstitial_done = Callable()
	load_interstitial()
	if cb.is_valid():
		cb.call()


# --- Consent / privacy (UMP) ----------------------------------------------------------------

func is_privacy_options_required() -> bool:
	return _backend != null and _backend.privacy_options_required()


## For a future Settings "Privacy Options" entry (no UI added in this pass).
func show_privacy_options(on_done: Callable = Callable()) -> void:
	if _backend != null:
		_backend.show_privacy_options(on_done if on_done.is_valid() else func() -> void: pass)


# --- helpers ------------------------------------------------------------------------------------

## Full-screen ads take over focus: silence the master bus while one is up, restore after.
func _duck_audio(duck: bool) -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	if duck:
		_muted_before = AudioServer.is_bus_mute(bus)
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, _muted_before)


func _schedule_retry(kind: String) -> void:
	if _retry_pending[kind] or not is_inside_tree():
		return
	var delay: float
	if kind == "rewarded":
		_rewarded_retry = minf(maxf(_rewarded_retry * 2.0, AdConfig.RETRY_SECONDS), AdConfig.RETRY_MAX_SECONDS)
		delay = _rewarded_retry
	else:
		_interstitial_retry = minf(maxf(_interstitial_retry * 2.0, AdConfig.RETRY_SECONDS), AdConfig.RETRY_MAX_SECONDS)
		delay = _interstitial_retry
	_retry_pending[kind] = true
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		_retry_pending[kind] = false
		if kind == "rewarded":
			load_rewarded()
		else:
			load_interstitial())
