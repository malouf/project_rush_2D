##============================================================================##
#  iap_manager.gd — In-app purchases (Battle Pass only)                        #
#  Adapted from: Document "Monétisation AAA" — no pay-to-win                  #
##============================================================================##

class_name IAPManager
extends Node

signal purchase_success(product_id: String, receipt: String)
signal purchase_failed(product_id: String, error_code: int)
signal purchase_canceled(product_id: String)
signal purchases_restored(restored_products: Array[String])

enum Product {
	BATTLE_PASS_PREMIUM = "battle_pass_premium",
	BATTLE_PASS_SKIP_TIER = "bp_skip_tier",
	COSMETIC_RARITY_UPGRADE = "cosmetic_rarity_upgrade",
}

var _store_initialized: bool = false
var _products: Dictionary = {}  # product_id → price info

func initialize() -> void:
	if not _store_initialized:
		# Apple App Store / Google Play Billing
		# IAPPlugin.set_up_store(["battle_pass_premium", "bp_skip_tier"])
		_store_initialized = true

func purchase(product_id: String) -> void:
	if not _store_initialized:
		purchase_failed.emit(product_id, -1)
		return
	# Validate: no "power" items, only cosmetic/BP
	assert(product_id in [Product.BATTLE_PASS_PREMIUM, Product.BATTLE_PASS_SKIP_TIER, Product.COSMETIC_RARITY_UPGRADE])
	# IAPPlugin.purchase(product_id)

func restore_purchases() -> void:
	# IAPPlugin.restore_purchases()
	var restored: Array[String] = []
	# On restore callback: restored.append(product_id)
	purchases_restored.emit(restored)

func validate_purchase(product_id: String, receipt: String) -> bool:
	# Server-side validation via Nakama RPC
	# Nakama.rpc("validate_purchase", {product_id, receipt, platform})
	return true  # Stub — always valid in dev

func get_product_info(product_id: String) -> Dictionary:
	return _products.get(product_id, {
		"price": "$4.99",
		"title": product_id,
		"description": "No pay-to-win content."
	})
