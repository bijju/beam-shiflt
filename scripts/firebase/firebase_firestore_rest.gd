class_name FirebaseFirestoreREST
extends RefCounted
## Cloud Firestore REST transport (Firebase REST Cloud Save Phase 2A).
## ISOLATED BACKEND VALIDATION ONLY - not yet wired into CloudSave/SaveManager.
##
## REST-only, matching FirebaseAuth (Phase 1): no native Firebase SDK, no
## google-services.json. Every call obtains a valid ID token through
## `FirebaseAuth.ensure_valid_token()` - this file never touches token/refresh
## logic itself, it only consumes FirebaseAuth's public API.
##
## Not an autoload: a plain RefCounted owned by whatever Node needs it (the
## Phase 2A test harness today; a future CloudSave Firestore backend later).
## HTTPRequest children are added to that owner node, since a RefCounted
## cannot itself be added to the SceneTree.
##
## Document paths are relative to the project's documents root
## (".../databases/(default)/documents/") - e.g. "users/<uid>/save/current".
## Callers build that path via current_user_document_path() so the UID is
## always read from FirebaseAuth, never hardcoded.
##
## Result contract for every on_done callback:
##   on_done(ok: bool, data: Dictionary, error_code: String, http_code: int)
## `data` is a decoded plain Dictionary (Firestore's typed Value wrapper is
## fully unwrapped here - it must never leak past this file).

const REQUEST_TIMEOUT_SECONDS := 12.0

var _owner: Node


func _init(owner: Node) -> void:
	_owner = owner


func current_user_document_path(sub_path: String) -> String:
	return "users/%s/%s" % [FirebaseAuth.get_uid(), sub_path]


## ---- Public API ----

func get_document(doc_path: String, on_done: Callable) -> void:
	_request(HTTPClient.METHOD_GET, doc_path, {}, false, on_done)


## Full overwrite (creates the document if absent). Fields not present in
## `data` are removed from the stored document - this is NOT a merge.
func set_document(doc_path: String, data: Dictionary, on_done: Callable) -> void:
	_request(HTTPClient.METHOD_PATCH, doc_path, data, false, on_done)


## Merge update via Firestore's updateMask (creates the document if absent).
## Only the top-level keys present in `data` are touched; every other
## existing field on the stored document is left untouched.
func update_document(doc_path: String, data: Dictionary, on_done: Callable) -> void:
	_request(HTTPClient.METHOD_PATCH, doc_path, data, true, on_done)


func delete_document(doc_path: String, on_done: Callable) -> void:
	_request(HTTPClient.METHOD_DELETE, doc_path, {}, false, on_done)


func document_exists(doc_path: String, on_done: Callable) -> void:
	get_document(doc_path, func(ok: bool, _data: Dictionary, err: String, code: int) -> void:
		if ok:
			on_done.call(true, "")
		elif err == "NOT_FOUND":
			on_done.call(false, "")
		else:
			on_done.call(false, err)
	)


## ---- Internal: request plumbing ----

func _request(method: int, doc_path: String, data: Dictionary, use_update_mask: bool, on_done: Callable) -> void:
	if not InternetManager.is_online:
		on_done.call(false, {}, "OFFLINE", 0)
		return

	var token_ok: bool = await FirebaseAuth.ensure_valid_token()
	if not token_ok:
		on_done.call(false, {}, "NO_AUTH", 0)
		return
	var uid := FirebaseAuth.get_uid()
	if uid == "":
		on_done.call(false, {}, "NO_AUTH", 0)
		return

	# Captured AFTER the token wait (which itself can yield across frames) so a
	# sign-out that happens during that wait is also caught, not just one that
	# happens during the HTTP round-trip itself.
	var gen := FirebaseAuth.get_session_generation()

	var url := "%s/%s" % [_documents_base(), doc_path]
	if use_update_mask:
		var mask_parts := PackedStringArray()
		for key in data.keys():
			mask_parts.append("updateMask.fieldPaths=%s" % str(key).uri_encode())
		if not mask_parts.is_empty():
			url += "?" + "&".join(mask_parts)

	var headers := PackedStringArray([
		"Authorization: Bearer %s" % FirebaseAuth.get_id_token(),
		"Content-Type: application/json",
	])

	var body := ""
	if method == HTTPClient.METHOD_PATCH:
		body = JSON.stringify({"fields": _encode_fields(data)})

	var req := HTTPRequest.new()
	req.timeout = REQUEST_TIMEOUT_SECONDS
	_owner.add_child(req)
	var err := req.request(url, headers, method, body)
	if err != OK:
		req.queue_free()
		on_done.call(false, {}, "REQUEST_FAILED", 0)
		return

	req.request_completed.connect(
		func(result: int, response_code: int, _resp_headers: PackedStringArray, resp_body: PackedByteArray) -> void:
			req.queue_free()
			if gen != FirebaseAuth.get_session_generation():
				on_done.call(false, {}, "STALE_SESSION", 0)
				return
			_handle_response(result, response_code, resp_body, on_done),
		CONNECT_ONE_SHOT
	)


func _handle_response(result: int, response_code: int, body: PackedByteArray, on_done: Callable) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		on_done.call(false, {}, "NETWORK_ERROR", 0)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	var json: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	if response_code >= 200 and response_code < 300:
		on_done.call(true, _decode_document(json), "", response_code)
		return
	on_done.call(false, {}, _extract_error_code(json, response_code), response_code)


func _documents_base() -> String:
	return "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents" % FirebaseConfig.PROJECT_ID


func _extract_error_code(json: Dictionary, http_code: int) -> String:
	var error_obj: Dictionary = json.get("error", {})
	var status := str(error_obj.get("status", ""))
	if status != "":
		return status
	match http_code:
		404:
			return "NOT_FOUND"
		403:
			return "PERMISSION_DENIED"
		401:
			return "UNAUTHENTICATED"
		0:
			return "REQUEST_FAILED"
		_:
			return "UNKNOWN_ERROR"


## ---- Internal: Firestore <-> Godot value (de)serialization ----
## Converts a plain Dictionary (strings/bools/ints/floats/null/Dictionary/
## Array) into Firestore REST's typed Value wrapper format, and back. This is
## the ONE place that format is ever produced or consumed - a future
## CloudSave Firestore backend must only ever see plain Dictionaries.

func _encode_fields(data: Dictionary) -> Dictionary:
	var out := {}
	for key in data.keys():
		out[str(key)] = _encode_value(data[key])
	return out


func _encode_value(value: Variant) -> Dictionary:
	match typeof(value):
		TYPE_NIL:
			return {"nullValue": null}
		TYPE_BOOL:
			return {"booleanValue": value}
		TYPE_INT:
			return {"integerValue": str(value)}
		TYPE_FLOAT:
			return {"doubleValue": value}
		TYPE_STRING, TYPE_STRING_NAME:
			return {"stringValue": str(value)}
		TYPE_DICTIONARY:
			return {"mapValue": {"fields": _encode_fields(value)}}
		TYPE_ARRAY:
			var values := []
			for item in value:
				values.append(_encode_value(item))
			return {"arrayValue": {"values": values}}
		_:
			# Unsupported type (e.g. a Resource/Object) - never silently drop
			# data; caller must not pass this. Stored as its string form so a
			# bug is visible instead of losing the field.
			push_warning("[FirebaseFirestoreREST] Unsupported value type %d encoded as string." % typeof(value))
			return {"stringValue": str(value)}


## `doc_json` is a whole Firestore document response ({"name":..., "fields":
## {...}, "createTime":..., "updateTime":...}) - returns just the decoded
## plain Dictionary of its fields ({} for a response with no "fields", e.g. an
## empty document).
func _decode_document(doc_json: Dictionary) -> Dictionary:
	var fields: Dictionary = doc_json.get("fields", {})
	return _decode_fields(fields)


func _decode_fields(fields: Dictionary) -> Dictionary:
	var out := {}
	for key in fields.keys():
		out[key] = _decode_value(fields[key])
	return out


func _decode_value(value: Dictionary) -> Variant:
	if value.has("stringValue"):
		return str(value["stringValue"])
	if value.has("booleanValue"):
		return bool(value["booleanValue"])
	if value.has("integerValue"):
		return int(str(value["integerValue"]))
	if value.has("doubleValue"):
		return float(value["doubleValue"])
	if value.has("nullValue"):
		return null
	if value.has("mapValue"):
		var map_fields: Dictionary = value["mapValue"].get("fields", {})
		return _decode_fields(map_fields)
	if value.has("arrayValue"):
		var raw_values: Array = value["arrayValue"].get("values", [])
		var decoded := []
		for item in raw_values:
			decoded.append(_decode_value(item))
		return decoded
	return null
