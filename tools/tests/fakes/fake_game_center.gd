extends RefCounted
## Duck-typed stand-ins for the iOS GameCenterManager extension objects.

class FakeError:
	extends RefCounted
	var code := 3
	var domain := "GKErrorDomain"
	var message := "boom"


class FakeGame:
	extends RefCounted
	var name := "beamshift_profile"
	var payload: Variant = PackedByteArray()
	var error: Variant = null

	func load_data(cb: Callable) -> void:
		cb.call(payload, error)


class FakePlayer:
	extends RefCounted
	signal conflicting_saved_games(player: Variant, games: Variant)
	var listener_registered := false
	var saved: Array = []
	var resolved: Array = []
	var games: Variant = []
	var fetch_error: Variant = null
	var save_error: Variant = null
	var resolve_error: Variant = null

	func register_listener() -> void:
		listener_registered = true

	func save_game_data(data: PackedByteArray, name: String, cb: Callable) -> void:
		saved.append([data, name])
		cb.call(null, save_error)

	func fetch_saved_games(cb: Callable) -> void:
		cb.call(games, fetch_error)

	func resolve_conflicting_saved_games(list: Array, data: PackedByteArray, cb: Callable) -> void:
		resolved.append([list, data])
		cb.call([], resolve_error)


class FakeManager:
	extends RefCounted
	signal authentication_result(status: bool)
	signal authentication_error(message: String)
	var local_player: Variant = null
	var authenticate_calls := 0

	func authenticate() -> void:
		authenticate_calls += 1
