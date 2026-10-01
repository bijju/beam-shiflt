extends Node
## Scriptable StoreManager backend (same contract as play_billing/store_kit backends).

signal state_changed
signal ownership_known(owned_ids: PackedStringArray, authoritative: bool)
signal purchase_failed(reason: String)
signal purchase_pending

var buyable := true
var live_price := ""
var purchases: Array = []
var restores := 0


func is_available() -> bool:
	return true


func can_purchase(_id: String) -> bool:
	return buyable


func price(_id: String) -> String:
	return live_price


func purchase(id: String) -> void:
	purchases.append(id)


func restore() -> void:
	restores += 1
