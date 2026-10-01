extends TestCase
## Play Billing and StoreKit backends, driven through duck-typed clients.

const PID := "no_forced_ads"


class FakeClient:
	extends Node
	var calls: Array = []
	var purchase_result := {"response_code": 0}

	func start_connection() -> void:
		calls.append("start")

	func query_product_details(ids: Variant, kind: Variant) -> void:
		calls.append(["details", ids, kind])

	func query_purchases(kind: Variant) -> void:
		calls.append(["purchases", kind])

	func purchase(id: String) -> Dictionary:
		calls.append(["purchase", id])
		return purchase_result

	func acknowledge_purchase(token: String) -> void:
		calls.append(["ack", token])


class FakeKit:
	extends RefCounted
	var calls: Array = []

	func purchase(id: String, extras: Array) -> void:
		calls.append(["purchase", id, extras])

	func restorePurchases() -> void:
		calls.append(["restore"])


func _pid() -> String:
	return StoreConfig.NO_FORCED_ADS


func _billing() -> Node:
	var b: Node = load("res://scripts/store/play_billing_backend.gd").new()
	runner.add_child(b)
	return b


func test_play_billing_flow() -> void:
	var b := _billing()
	ok(not b.is_available(), "no plugin on desktop")
	ok(not b.can_purchase(_pid()))
	eq(b.price(_pid()), "")
	var failures := watch(b.purchase_failed)
	var owned := watch(b.ownership_known)
	var pending := watch(b.purchase_pending)
	var changed := watch(b.state_changed)
	b.purchase(_pid())
	eq(failures[0][0], "unavailable")
	var client := FakeClient.new()
	b.add_child(client)
	b._client = client
	b.restore()  # not connected
	eq(failures[1][0], "unavailable")
	b._on_connected()
	ok(b._connected)
	eq(changed.size(), 1)
	b._on_product_details({"response_code": 0, "product_details": [
		{"product_id": _pid(), "one_time_purchase_offer_details": {"formatted_price": "$2.99"}},
		"junk",
		{"product_id": "other"},
	]})
	eq(b.price(_pid()), "$2.99")
	ok(b.can_purchase(_pid()))
	b._on_product_details({"response_code": 6, "debug_message": "x"})
	b._on_product_details({"response_code": 0, "product_details": []})
	b.restore()
	ok(client.calls.has(["purchases", 0]) or client.calls.size() > 3)
	for code in [0, 7, 1, 99]:
		client.purchase_result = {"response_code": code}
		b.purchase(_pid())
	ok(failures.size() >= 4)
	b._on_purchases_queried({"response_code": 6})
	b._on_purchases_queried({"response_code": 0, "purchases": []})
	eq(owned[0][1], true)
	b._on_purchase_updated({"response_code": 1})
	b._on_purchase_updated({"response_code": 5})
	b._on_purchase_updated({"response_code": 0, "purchases": []})
	b._on_purchase_updated({"response_code": 0, "purchases": [{"product_ids": [_pid()], "purchase_state": 1, "is_acknowledged": false, "purchase_token": "t"}]})
	ok(client.calls.has(["ack", "t"]))
	b._on_acknowledged({"response_code": 0})
	b._on_acknowledged({"response_code": 6, "debug_message": "no"})
	eq(b._scan_purchases("nope").size(), 0)
	b._scan_purchases(["junk", {"product_ids": ["unknown"]}, {"product_ids": [_pid()], "purchase_state": 2}, {"product_ids": [_pid()], "purchase_state": 0}])
	ok(pending.size() >= 1)
	eq(b._formatted_price({"one_time_purchase_offer_details_list": [{"formatted_price": "A"}]}), "A")
	eq(b._formatted_price({"formatted_price": "B"}), "B")
	eq(b._product_id({"sku": _pid()}), _pid())
	eq(b._product_id({"id": "nope"}), "")
	Engine.time_scale = 40.0
	b._on_connect_error(1, "x")
	await frames(1)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1500:
		await frames(1)
	Engine.time_scale = 1.0
	b.queue_free()


func test_store_kit_flow() -> void:
	var k: Node = load("res://scripts/store/store_kit_backend.gd").new()
	runner.add_child(k)
	ok(not k.is_available())
	var failures := watch(k.purchase_failed)
	var owned := watch(k.ownership_known)
	var pending := watch(k.purchase_pending)
	var changed := watch(k.state_changed)
	k.purchase(_pid())
	eq(failures[0][0], "unavailable")
	k.restore()
	eq(failures[1][0], "unavailable")
	ok(not k.can_purchase(_pid()))
	eq(k.price(_pid()), "")
	k._on_products(1, [])
	k._on_products(0, [])
	k._on_products(0, [{"id": _pid(), "displayPrice": "$2.99"}, "junk", {"id": "other"}])
	eq(k.price(_pid()), "$2.99")
	ok(changed.size() >= 2)
	var kit := FakeKit.new()
	k._kit = kit
	ok(k.can_purchase(_pid()))
	k.purchase(_pid())
	eq(kit.calls[0][0], "purchase")
	k._on_purchase_complete(0)
	eq(owned.size(), 1)
	ok(k._owned.has(_pid()))
	k._on_purchase_complete(0)  # nothing in flight
	k._purchasing = _pid()
	k._on_purchase_complete(3)
	eq(failures[2][0], "")
	k._purchasing = _pid()
	k._on_purchase_complete(2)
	eq(pending.size(), 1)
	k._purchasing = _pid()
	k._on_purchase_complete(9)
	eq(failures[3][0], "failed")
	k._purchasing = _pid()
	k._on_purchased_transactions([{"productId": _pid()}, "junk", {"productId": "other"}])
	ok(k._owned.has(_pid()))
	k._on_revoked_transactions([{"productId": "other"}])
	k._on_revoked_transactions([{"productId": _pid()}])
	ok(not k._owned.has(_pid()))
	k.restore()
	k._on_restore_complete(1)
	eq(failures[failures.size() - 1][0], "failed")
	k._on_restore_complete(0)  # restarts (no plugin here) and settles with nothing owned
	Engine.time_scale = 40.0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1500:
		await frames(1)
	Engine.time_scale = 1.0
	k._start()
	k.queue_free()

