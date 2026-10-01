extends TestCase

const FakeStore := preload("res://tools/tests/fakes/fake_store_backend.gd")

var _snap: Dictionary


func before_each() -> void:
	_snap = SaveManager.to_dict().duplicate(true)


func after_each() -> void:
	SaveManager._apply_data(_snap.duplicate(true))


func _store(with_backend := true) -> Node:
	var sm: Node = load("res://scripts/managers/store_manager.gd").new()
	runner.add_child(sm)
	if with_backend:
		var b := FakeStore.new()
		sm.add_child(b)
		sm._backend = b
		b.state_changed.connect(sm._on_state_changed)
		b.ownership_known.connect(sm._on_ownership_known)
		b.purchase_failed.connect(sm._on_purchase_failed)
		b.purchase_pending.connect(sm._on_purchase_pending)
	return sm


func test_store_config() -> void:
	ok(StoreConfig.product_ids().has(StoreConfig.NO_FORCED_ADS))
	ok(StoreConfig.sells(StoreConfig.NO_FORCED_ADS))
	ok(not StoreConfig.sells("nope"))
	ok(StoreConfig.fallback_price(StoreConfig.NO_FORCED_ADS) != "")
	eq(StoreConfig.fallback_price("nope"), "")


func test_without_backend() -> void:
	var sm := _store(false)
	var msgs := watch(sm.purchase_finished)
	ok(not sm.has_store())
	ok(not sm.can_purchase())
	ok(not sm.is_busy())
	eq(sm.price_text(), StoreConfig.fallback_price(StoreConfig.NO_FORCED_ADS))
	sm.purchase()
	eq(msgs[0][1], StoreManager_MSG("MSG_UNAVAILABLE", sm))
	sm.restore_purchases()
	eq(msgs[1][1], StoreManager_MSG("MSG_UNAVAILABLE", sm))
	sm.queue_free()


func StoreManager_MSG(name: String, sm: Node) -> String:
	return sm.get(name)


func test_purchase_success_flow() -> void:
	var sm := _store()
	var b: Node = sm._backend
	var msgs := watch(sm.purchase_finished)
	ok(sm.has_store())
	ok(sm.can_purchase())
	b.live_price = "$1.99"
	eq(sm.price_text(), "$1.99")
	sm.purchase()
	ok(sm.is_busy())
	ok(not sm.can_purchase())
	sm.purchase()  # busy: ignored
	eq(b.purchases.size(), 1)
	b.ownership_known.emit(PackedStringArray([StoreConfig.NO_FORCED_ADS]), true)
	ok(sm.owns_no_forced_ads())
	eq(msgs[0][1], sm.MSG_THANKS)
	ok(not sm.is_busy())
	sm.purchase()
	eq(msgs[1][1], sm.MSG_ALREADY_OWNED)
	sm.queue_free()


func test_restore_flows() -> void:
	var sm := _store()
	var b: Node = sm._backend
	var msgs := watch(sm.purchase_finished)
	sm.restore_purchases()
	sm.restore_purchases()
	eq(b.restores, 1)
	b.ownership_known.emit(PackedStringArray(), true)
	eq(msgs[0][1], sm.MSG_NOTHING)
	sm.restore_purchases()
	b.ownership_known.emit(PackedStringArray([StoreConfig.NO_FORCED_ADS]), true)
	eq(msgs[1][1], sm.MSG_RESTORED)
	# a later authoritative query with nothing owned revokes (refund)
	b.ownership_known.emit(PackedStringArray(), true)
	ok(not sm.owns_no_forced_ads())
	# non-authoritative never revokes
	SaveManager.set_entitlement(StoreConfig.NO_FORCED_ADS, true)
	b.ownership_known.emit(PackedStringArray(), false)
	ok(sm.owns_no_forced_ads())
	# purchase answered by an already-owned query
	SaveManager.set_entitlement(StoreConfig.NO_FORCED_ADS, false)
	sm.purchase()
	SaveManager.set_entitlement(StoreConfig.NO_FORCED_ADS, true)
	b.ownership_known.emit(PackedStringArray([StoreConfig.NO_FORCED_ADS]), true)
	eq(msgs[msgs.size() - 1][1], sm.MSG_ALREADY_OWNED)
	sm.queue_free()


func test_failure_and_pending() -> void:
	var sm := _store()
	var b: Node = sm._backend
	var msgs := watch(sm.purchase_finished)
	b.buyable = false
	ok(not sm.can_purchase())
	sm.purchase()
	b.purchase_failed.emit("unavailable")
	eq(msgs[0][1], sm.MSG_UNAVAILABLE)
	sm.purchase()
	b.purchase_failed.emit("failed")
	eq(msgs[1][1], sm.MSG_FAILED)
	sm.purchase()
	b.purchase_failed.emit("")
	eq(msgs[2][1], "")
	sm.purchase()
	b.purchase_pending.emit()
	eq(msgs[3][1], sm.MSG_PENDING)
	b.state_changed.emit()
	sm.queue_free()
