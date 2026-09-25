class_name AdBackendFake
extends AdBackend
## Scriptable stand-in used ONLY by tests/dev drivers (never selected on a device).
## Events are emitted deferred, like the real plugin. `load_ok`/`show_mode` script
## the outcome: show_mode = "reward" | "close_no_reward" | "fail".

var load_ok := true
var show_mode := "reward"
var sdk_ok := true
var rewarded_shows := 0
var interstitial_shows := 0
var _rw := false
var _it := false


func initialize() -> void:
	initialized.emit.call_deferred(sdk_ok)


func load_rewarded() -> void:
	if _rw:
		return
	if load_ok:
		_rw = true
		rewarded_loaded.emit.call_deferred()
	else:
		rewarded_load_failed.emit.call_deferred("fake load failure")


func has_rewarded() -> bool:
	return _rw


func show_rewarded() -> bool:
	if not _rw:
		return false
	_rw = false
	rewarded_shows += 1
	match show_mode:
		"fail":
			rewarded_show_failed.emit.call_deferred("fake show failure")
		"close_no_reward":
			rewarded_opened.emit.call_deferred()
			rewarded_closed.emit.call_deferred()
		_:
			rewarded_opened.emit.call_deferred()
			reward_earned.emit.call_deferred()
			rewarded_closed.emit.call_deferred()
	return true


func load_interstitial() -> void:
	if _it:
		return
	if load_ok:
		_it = true
		interstitial_loaded.emit.call_deferred()
	else:
		interstitial_load_failed.emit.call_deferred("fake load failure")


func has_interstitial() -> bool:
	return _it


func show_interstitial() -> bool:
	if not _it:
		return false
	_it = false
	interstitial_shows += 1
	if show_mode == "fail":
		interstitial_show_failed.emit.call_deferred("fake show failure")
	else:
		interstitial_opened.emit.call_deferred()
		interstitial_closed.emit.call_deferred()
	return true
