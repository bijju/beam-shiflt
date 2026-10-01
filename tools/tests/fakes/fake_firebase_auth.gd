extends "res://scripts/managers/firebase_auth.gd"
## Test double: the REAL FirebaseAuth logic with only the HTTP transport replaced by a
## scripted queue ({"ok","json","err"}), so no network is ever touched.

var queue: Array = []
var posted: Array = []


func _post(url: String, _headers: PackedStringArray, body: String, on_done: Callable) -> void:
	posted.append({"url": url, "body": body})
	var r: Dictionary = queue.pop_front() if not queue.is_empty() else {"ok": false, "json": {}, "err": "UNSCRIPTED"}
	on_done.call_deferred(r["ok"], r.get("json", {}), r.get("err", ""))
