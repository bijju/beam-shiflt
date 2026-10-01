extends RefCounted
## Stand-in for the iOS AuthenticationServices objects and Apple credential.

signal completed(callback_url: String)
signal canceled
signal failed(message: String)
signal authorization_completed(credential: Object)
signal authorization_failed(message: String)

var start_result := true
var starts: Array = []
var scopes_calls: Array = []
var identity_token := PackedByteArray()


func start(url: String, scheme: String, ephemeral: bool) -> bool:
	starts.append([url, scheme, ephemeral])
	return start_result


func signin_with_scopes(scopes: Array) -> void:
	scopes_calls.append(scopes)


func get_identity_token() -> PackedByteArray:
	return identity_token
