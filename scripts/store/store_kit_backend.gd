extends Node
## App Store half of the store: godot-store-kit 1.5 (StoreKit 2, SwiftGodot, needs iOS 17),
## driven by class name through ClassDB so this compiles on every platform; the extension
## exists only in the iOS build (CI copies it from third_party/godot_store_kit/).
## Same signals/methods as play_billing_backend.gd. Every plugin signal is connected
## CONNECT_DEFERRED: SwiftGodot emits from Swift Tasks off the main thread, where
## add_child() is refused and UI rebuilt from the callback comes up empty.

const PLUGIN_CLASS := "GodotStoreKit"
const STATUS_OK := 0
const STATUS_PENDING := 2
const STATUS_CANCELLED := 3
## The plugin only reports entitlements it found, never an empty list, so "owns nothing"
## after a restore has to be concluded by the clock.
const RESTORE_SETTLE_SECONDS := 3.0

signal state_changed
signal ownership_known(owned_ids: PackedStringArray, authoritative: bool)
signal purchase_failed(reason: String)
signal purchase_pending

var _kit: Object = null
var _prices := {}
var _owned := PackedStringArray()
var _purchasing := ""
var _restore_heard := false


func is_available() -> bool:
	return ClassDB.class_exists(PLUGIN_CLASS) and ClassDB.can_instantiate(PLUGIN_CLASS)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start()


func can_purchase(product_id: String) -> bool:
	return _kit != null and _prices.has(product_id)


func price(product_id: String) -> String:
	return str(_prices.get(product_id, ""))


func purchase(product_id: String) -> void:
	if not can_purchase(product_id):
		purchase_failed.emit("unavailable")
		return
	_purchasing = product_id
	_kit.call("purchase", product_id, [])


## Sync with the App Store, then read entitlements back through a fresh plugin object
## (the plugin only lists entitlements when it initialises).
func restore() -> void:
	if _kit == null:
		purchase_failed.emit("unavailable")
		_start()
		return
	_kit.call("restorePurchases")


func _start() -> void:
	if not is_available():
		return
	_kit = ClassDB.instantiate(PLUGIN_CLASS)
	if _kit == null:
		return
	_kit.connect("purchased_transactions", _on_purchased_transactions, CONNECT_DEFERRED)
	_kit.connect("revoked_transactions", _on_revoked_transactions, CONNECT_DEFERRED)
	_kit.connect("purchase_complete", _on_purchase_complete, CONNECT_DEFERRED)
	_kit.connect("get_products_complete", _on_products, CONNECT_DEFERRED)
	_kit.connect("restore_purchases_complete", _on_restore_complete, CONNECT_DEFERRED)
	var ids: Array[String] = [] # the plugin wants a typed String array
	for id in StoreConfig.product_ids():
		ids.append(id)
	_kit.call("initialize", ids)
	_kit.call("getProducts", ids)


func _on_products(status: int, products: Array) -> void:
	if status != STATUS_OK:
		push_warning("StoreManager/iOS: product query failed (status %d) - offline, wrong ID, or the Paid Apps Agreement is not Active." % status)
		return
	for product in products:
		if typeof(product) == TYPE_DICTIONARY and StoreConfig.sells(str(product.get("id", ""))):
			_prices[str(product["id"])] = str(product.get("displayPrice", ""))
	if _prices.is_empty():
		push_warning("StoreManager/iOS: no products returned - check App Store Connect IDs and the Paid Apps Agreement.")
	state_changed.emit()


## The account's whole current entitlement set (start-up, after a purchase, on push).
func _on_purchased_transactions(transactions: Array) -> void:
	_owned = _ours_in(transactions)
	_restore_heard = true
	if _owned.has(_purchasing):
		_purchasing = ""
	ownership_known.emit(_owned, true)


func _on_revoked_transactions(transactions: Array) -> void:
	var revoked := _ours_in(transactions)
	if revoked.is_empty():
		return
	var still := PackedStringArray()
	for id in _owned:
		if not revoked.has(id):
			still.append(id)
	_owned = still
	ownership_known.emit(_owned, true)


func _on_purchase_complete(status: int) -> void:
	var product := _purchasing
	_purchasing = ""
	match status:
		STATUS_OK:
			if product != "" and not _owned.has(product):
				_owned.append(product)
				ownership_known.emit(_owned, false)
		STATUS_CANCELLED:
			purchase_failed.emit("")
		STATUS_PENDING:
			purchase_pending.emit() # Ask to Buy: the transaction listener delivers it later
		_:
			purchase_failed.emit("failed")


func _on_restore_complete(status: int) -> void:
	if status != STATUS_OK:
		purchase_failed.emit("failed")
		return
	_restore_heard = false
	_prices.clear()
	_kit = null
	_start()
	await get_tree().create_timer(RESTORE_SETTLE_SECONDS, true, false, true).timeout
	if not _restore_heard:
		_owned = PackedStringArray()
		ownership_known.emit(_owned, true)


func _ours_in(transactions: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for tx in transactions:
		if typeof(tx) != TYPE_DICTIONARY:
			continue
		var id := str(tx.get("productId", ""))
		if StoreConfig.sells(id) and not out.has(id):
			out.append(id)
	return out
