extends Node
## Scriptable stand-in for a CloudSave backend (same contract as the real ones).

signal sign_in_changed(is_signed_in: bool)
signal profile_loaded(profile: Dictionary)
signal conflict_found(profiles: Array)
signal push_finished(ok: bool)

var last_error := ""
var available := true
var service := "Fake Cloud"
var pulls := 0
var pushes: Array = []
var resolved: Array = []
var sign_ins := 0


func is_available() -> bool:
	return available


func service_name() -> String:
	return service


func sign_in() -> void:
	sign_ins += 1


func pull() -> void:
	pulls += 1


func push(payload: Dictionary, played_ms: int) -> void:
	pushes.append([payload, played_ms])


func resolve_conflict(winner: Dictionary, played_ms: int) -> void:
	resolved.append([winner, played_ms])
