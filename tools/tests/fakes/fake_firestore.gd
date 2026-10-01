extends FirebaseFirestoreREST
## Firestore wrapper test doubles. With `scripted = true` get/set return queued results;
## otherwise the REAL _request runs against `base` (a local TCPServer the test controls,
## or an invalid URL) - no external traffic either way.

var scripted := false
var queue: Array = []
var calls: Array = []
var base := "ht!tp://bad"


func _documents_base() -> String:
	return base


func _next() -> Array:
	return queue.pop_front() if not queue.is_empty() else [true, {}, "", 200]


func get_document(doc_path: String, on_done: Callable) -> void:
	if not scripted:
		super.get_document(doc_path, on_done)
		return
	calls.append(["get", doc_path])
	var r := _next()
	on_done.call(r[0], r[1], r[2], r[3])


func set_document(doc_path: String, data: Dictionary, on_done: Callable) -> void:
	if not scripted:
		super.set_document(doc_path, data, on_done)
		return
	calls.append(["set", doc_path, data])
	var r := _next()
	on_done.call(r[0], r[1], r[2], r[3])
