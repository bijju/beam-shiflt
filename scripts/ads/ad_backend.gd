class_name AdBackend
extends RefCounted
## Platform seam under AdManager (ADS_MONETIZATION.md). Game code never touches an SDK:
## AdManager talks to one AdBackend - the real Google Mobile Ads one on Android/iOS
## (ad_backend_admob.gd) or a scriptable fake for tests (ad_backend_fake.gd). All events
## are delivered on the main thread, never synchronously from inside the call that
## caused them.

signal initialized(ok: bool)
signal rewarded_loaded
signal rewarded_load_failed(message: String)
signal rewarded_opened
signal reward_earned
signal rewarded_closed
signal rewarded_show_failed(message: String)
signal interstitial_loaded
signal interstitial_load_failed(message: String)
signal interstitial_opened
signal interstitial_closed
signal interstitial_show_failed(message: String)


## Runs consent (UMP) then SDK init, then emits `initialized`.
func initialize() -> void:
	initialized.emit(false)


func load_rewarded() -> void:
	rewarded_load_failed.emit("not supported")


func has_rewarded() -> bool:
	return false


## true = the show call was issued (events follow).
func show_rewarded() -> bool:
	return false


func load_interstitial() -> void:
	interstitial_load_failed.emit("not supported")


func has_interstitial() -> bool:
	return false


func show_interstitial() -> bool:
	return false


func privacy_options_required() -> bool:
	return false


func show_privacy_options(_on_done: Callable) -> void:
	pass


## Drops a loaded interstitial (No Forced Ads was just bought).
func discard_interstitial() -> void:
	pass


## Empties everything the SDK still holds for us (AdManager._exit_tree). Idempotent.
func release() -> void:
	pass
