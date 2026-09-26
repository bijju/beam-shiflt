extends Node
## Google Play half of the store (GodotGooglePlayBilling 3.3.0, addons/GodotGooglePlayBilling).
## The ONLY file naming a class from that plugin; loaded by path from StoreManager on
## Android only, so a build without the plugin never compiles it. Everything sold is a
## one-time, non-consumed product: bought once, ACKNOWLEDGED (Play auto-refunds anything
## left unacknowledged for 3 days), and restored by the purchase query on any device.
## Failure reasons crossing the seam: "" (cancelled), "unavailable", "failed".

const PLUGIN_SINGLETON := "GodotGooglePlayBilling"
## Play drops the connection whenever the Play Store app updates itself; reconnect gently.
const RECONNECT_SECONDS := 20.0

signal state_changed
## `authoritative` = a full purchase query: the only answer allowed to revoke.
signal ownership_known(owned_ids: PackedStringArray, authoritative: bool)
signal purchase_failed(reason: String)
signal purchase_pending

var _client = null
var _connected := false
var _prices := {} # product id -> formatted price, only for products Play confirmed


func is_available() -> bool:
	return Engine.has_singleton(PLUGIN_SINGLETON)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not is_available():
		return
	_client = BillingClient.new()
	add_child(_client)
	_client.connected.connect(_on_connected)
	_client.disconnected.connect(_on_disconnected)
	_client.connect_error.connect(_on_connect_error)
	_client.query_product_details_response.connect(_on_product_details)
	_client.query_purchases_response.connect(_on_purchases_queried)
	_client.on_purchase_updated.connect(_on_purchase_updated)
	_client.acknowledge_purchase_response.connect(_on_acknowledged)
	_client.start_connection()


## Play refuses a purchase for a product whose details were never fetched.
func can_purchase(product_id: String) -> bool:
	return _connected and _prices.has(product_id)


func price(product_id: String) -> String:
	return str(_prices.get(product_id, ""))


func purchase(product_id: String) -> void:
	if not can_purchase(product_id):
		purchase_failed.emit("unavailable")
		return
	var result: Dictionary = _client.purchase(product_id)
	var code := int(result.get("response_code", BillingClient.BillingResponseCode.ERROR))
	match code:
		BillingClient.BillingResponseCode.OK:
			pass # the result arrives through on_purchase_updated
		BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
			restore() # bought on another device / reinstalled: let the query settle it
		BillingClient.BillingResponseCode.USER_CANCELED:
			purchase_failed.emit("")
		_:
			purchase_failed.emit("failed")


func restore() -> void:
	if not _connected:
		purchase_failed.emit("unavailable")
		_client.start_connection()
		return
	_client.query_purchases(BillingClient.ProductType.INAPP)


func _on_connected() -> void:
	_connected = true
	_client.query_product_details(StoreConfig.product_ids(), BillingClient.ProductType.INAPP)
	_client.query_purchases(BillingClient.ProductType.INAPP)
	state_changed.emit()


func _on_disconnected() -> void:
	_connected = false
	state_changed.emit()
	await get_tree().create_timer(RECONNECT_SECONDS, true, false, true).timeout
	if not _connected:
		_client.start_connection()


func _on_connect_error(_response_code: int, _debug_message: String) -> void:
	_on_disconnected()


func _on_product_details(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		push_warning("StoreManager/Play: product query failed: %s" % str(response.get("debug_message", "")))
		return
	var learned := false
	for product in response.get("product_details", []):
		if typeof(product) != TYPE_DICTIONARY:
			continue
		var id := _product_id(product)
		if id != "":
			_prices[id] = _formatted_price(product)
			learned = true
	if not learned:
		push_warning("StoreManager/Play: no products returned - check the IDs in Play Console and that the build was installed from Play.")
	state_changed.emit()


func _on_purchases_queried(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		return # offline / Play unhappy: silence is not evidence the player owns nothing
	ownership_known.emit(_scan_purchases(response.get("purchases", [])), true)


func _on_purchase_updated(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	if code == BillingClient.BillingResponseCode.USER_CANCELED:
		purchase_failed.emit("")
		return
	if code != BillingClient.BillingResponseCode.OK:
		purchase_failed.emit("failed")
		return
	var owned := _scan_purchases(response.get("purchases", []))
	if not owned.is_empty():
		ownership_known.emit(owned, false) # an update only ever adds


func _on_acknowledged(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		push_warning("StoreManager/Play: acknowledge failed: %s" % str(response.get("debug_message", "")))


func _scan_purchases(purchases: Variant) -> PackedStringArray:
	var owned := PackedStringArray()
	if typeof(purchases) != TYPE_ARRAY:
		return owned
	for p in purchases:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var ours := PackedStringArray()
		for id in p.get("product_ids", []):
			if StoreConfig.sells(str(id)):
				ours.append(str(id))
		if ours.is_empty():
			continue
		var state := int(p.get("purchase_state", 0))
		if state == BillingClient.PurchaseState.PENDING:
			purchase_pending.emit()
			continue
		if state != BillingClient.PurchaseState.PURCHASED:
			continue
		for id in ours:
			if not owned.has(id):
				owned.append(id)
		if not bool(p.get("is_acknowledged", false)):
			_client.acknowledge_purchase(str(p.get("purchase_token", "")))
	return owned


## The details key has moved around across billing library versions.
func _product_id(product: Dictionary) -> String:
	for key in ["product_id", "id", "sku"]:
		if product.has(key) and StoreConfig.sells(str(product[key])):
			return str(product[key])
	return ""


func _formatted_price(product: Dictionary) -> String:
	var offer: Variant = product.get("one_time_purchase_offer_details", null)
	if typeof(offer) == TYPE_DICTIONARY and offer.has("formatted_price"):
		return str(offer["formatted_price"])
	var offers: Variant = product.get("one_time_purchase_offer_details_list", null)
	if typeof(offers) == TYPE_ARRAY and not offers.is_empty() and typeof(offers[0]) == TYPE_DICTIONARY and offers[0].has("formatted_price"):
		return str(offers[0]["formatted_price"])
	return str(product.get("formatted_price", ""))
