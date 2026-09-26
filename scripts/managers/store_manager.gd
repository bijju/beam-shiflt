extends Node
## StoreManager - real-money purchases and the entitlements they grant (6th autoload; earns
## rule 6 because store connection state, prices and the in-flight purchase must outlive
## every scene, and Settings, AdManager and the pause/complete screens all read it).
## Full design: STORE_RELEASE.md.
##
## SDK-free policy layer over one platform backend loaded BY PATH, only on a phone:
## Google Play Billing on Android (play_billing_backend.gd), StoreKit 2 via the
## godot-store-kit GDExtension on iOS (store_kit_backend.gd). Everywhere else (desktop,
## editor, a build missing the plugin) the store reports itself unavailable and the game
## runs normally.
##
## Entitlements live in SaveManager (correct offline and on the first frame) and are
## re-checked against the store at every launch. Only an AUTHORITATIVE answer (a completed
## full purchase query) may revoke; a failed or offline query never takes a purchase away.

const ANDROID_BACKEND := "res://scripts/store/play_billing_backend.gd"
const IOS_BACKEND := "res://scripts/store/store_kit_backend.gd"

## Readiness, a price or an entitlement changed.
signal changed
## A purchase or restore finished. `message` is player-facing text, empty when the player
## simply cancelled.
signal purchase_finished(success: bool, message: String)

const MSG_UNAVAILABLE := "The store is not available right now. Please try again later."
const MSG_FAILED := "The purchase could not be completed."
const MSG_PENDING := "Your purchase is pending approval. It will unlock automatically."
const MSG_THANKS := "Thank you! Forced ads are gone."
const MSG_RESTORED := "Purchases restored."
const MSG_ALREADY_OWNED := "You already own this."
const MSG_NOTHING := "No purchases to restore on this account."

# Untyped: the backend script only compiles where its plugin is installed.
var _backend = null
var _busy := false
var _restoring := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var path := ""
	match OS.get_name():
		"Android":
			path = ANDROID_BACKEND
		"iOS":
			path = IOS_BACKEND
	if path == "":
		return
	var script: Script = load(path)
	if script == null:
		push_warning("StoreManager: backend %s failed to load; store disabled." % path)
		return
	_backend = script.new()
	add_child(_backend)
	if not _backend.is_available():
		push_warning("StoreManager: billing plugin missing from this build; store disabled.")
		_backend.queue_free()
		_backend = null
		return
	_backend.state_changed.connect(_on_state_changed, CONNECT_DEFERRED)
	_backend.ownership_known.connect(_on_ownership_known, CONNECT_DEFERRED)
	_backend.purchase_failed.connect(_on_purchase_failed, CONNECT_DEFERRED)
	_backend.purchase_pending.connect(_on_purchase_pending, CONNECT_DEFERRED)


## True when this platform has a store at all (Settings shows the store rows only then).
func has_store() -> bool:
	return _backend != null


func owns_no_forced_ads() -> bool:
	return SaveManager.has_entitlement(StoreConfig.NO_FORCED_ADS)


## A purchase can be launched right now (connected and the product confirmed).
func can_purchase(product_id: String = StoreConfig.NO_FORCED_ADS) -> bool:
	return _backend != null and not _busy and _backend.can_purchase(product_id)


func is_busy() -> bool:
	return _busy


## The store's own localised price when known, the configured fallback otherwise.
func price_text(product_id: String = StoreConfig.NO_FORCED_ADS) -> String:
	if _backend != null:
		var live: String = _backend.price(product_id)
		if live != "":
			return live
	return StoreConfig.fallback_price(product_id)


func purchase(product_id: String = StoreConfig.NO_FORCED_ADS) -> void:
	if SaveManager.has_entitlement(product_id):
		purchase_finished.emit(true, MSG_ALREADY_OWNED)
		return
	if _backend == null:
		purchase_finished.emit(false, MSG_UNAVAILABLE)
		return
	if _busy:
		return
	_busy = true
	_restoring = false
	changed.emit()
	_backend.purchase(product_id)


func restore_purchases() -> void:
	if _backend == null:
		purchase_finished.emit(false, MSG_UNAVAILABLE)
		return
	if _busy:
		return
	_busy = true
	_restoring = true
	changed.emit()
	_backend.restore()


func _on_state_changed() -> void:
	changed.emit()


func _on_ownership_known(owned_ids: PackedStringArray, authoritative: bool) -> void:
	var newly_granted := false
	for product_id in StoreConfig.product_ids():
		if owned_ids.has(product_id):
			if SaveManager.set_entitlement(product_id, true):
				newly_granted = true
				_apply_grant(product_id)
		elif authoritative:
			SaveManager.set_entitlement(product_id, false) # refund / revocation
	changed.emit()
	if not _busy:
		return
	_busy = false
	var owns_any := not owned_ids.is_empty()
	if _restoring:
		purchase_finished.emit(owns_any, MSG_RESTORED if owns_any else MSG_NOTHING)
	elif newly_granted:
		purchase_finished.emit(true, MSG_THANKS)
	elif owns_any:
		purchase_finished.emit(true, MSG_ALREADY_OWNED)
	changed.emit()


func _apply_grant(product_id: String) -> void:
	if product_id == StoreConfig.NO_FORCED_ADS:
		AdManager.on_forced_ads_removed()


func _on_purchase_failed(reason: String) -> void:
	_busy = false
	var message := ""
	match reason:
		"unavailable":
			message = MSG_UNAVAILABLE
		"failed":
			message = MSG_FAILED
	purchase_finished.emit(false, message)
	changed.emit()


func _on_purchase_pending() -> void:
	_busy = false
	purchase_finished.emit(false, MSG_PENDING)
	changed.emit()
