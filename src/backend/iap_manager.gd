##============================================================================##
#  iap_manager.gd — In-App Purchase (IAP) manager                                #
#  Supports: Google Play, Apple App Store, Huawei AppGallery                   #
##============================================================================##

class_name IAPManager
extends Node

signal product_loaded(product: IAPProduct)
signal purchase_successful(product: IAPProduct, receipt: String)
signal purchase_failed(product_id: String, error: String)
signal purchase_restored(product: IAPProduct)
signal catalog_loaded(products: Array)

const PRODUCT_TYPE_CONSUMABLE = "consumable"
const PRODUCT_TYPE_NON_CONSUMABLE = "non_consumable"
const PRODUCT_TYPE_SUBSCRIPTION = "subscription"

var _products: Dictionary = {}
var _initialized: bool = false
var _pending_purchase: String = ""


class_name IAPProduct
extends RefCounted

var id: String
var title: String
var description: String
var price: String  # Localized price string
var price_value: float  # Numeric price
var currency: String  # ISO 4217
var product_type: String
var icon: Texture2D


func _ready() -> void:
	_initialize()


## Initialize the store
func _initialize() -> void:
	# STUB: In Phase 7, call real SDK:
	# if OS.get_name() == "Android":
	#     # Google Play Billing
	#     GooglePlayBilling.initialize()
	#     GooglePlayBilling.connect("connect_complete", _on_connected)
	#     GooglePlayBilling.connect("disconnected", _on_disconnected)
	# elif OS.get_name() == "iOS":
	#     # StoreKit
	#     StoreKit.initialize()
	#     StoreKit.connect("products_loaded", _on_products_loaded)
	#     StoreKit.connect("purchase_completed", _on_purchase_completed)
	# elif OS.get_name() == "HTML5":
	#     # Web Monetization
	#     pass
	_initialized = true


## Load product catalog
func load_catalog(product_ids: Array) -> void:
	# STUB: In Phase 7:
	# if OS.get_name() == "Android":
	#     GooglePlayBilling.query_details(product_ids)
	# elif OS.get_name() == "iOS":
	#     StoreKit.request_products(product_ids)
	# Default test catalog
	var default_catalog: Array = [
		_create_product("gems_100", "100 Gems", "0.99", PRODUCT_TYPE_CONSUMABLE),
		_create_product("gems_500", "500 Gems", "3.99", PRODUCT_TYPE_CONSUMABLE),
		_create_product("gems_1200", "1200 Gems", "7.99", PRODUCT_TYPE_CONSUMABLE),
		_create_product("battle_pass", "Battle Pass", "4.99", PRODUCT_TYPE_NON_CONSUMABLE),
		_create_product("remove_ads", "Remove Ads", "1.99", PRODUCT_TYPE_NON_CONSUMABLE),
	]
	for product in default_catalog:
		_products[product.id] = product
		product_loaded.emit(product)
	catalog_loaded.emit(default_catalog)


func _create_product(id: String, title: String, price: String, product_type: String) -> IAPProduct:
	var product = IAPProduct.new()
	product.id = id
	product.title = title
	product.price = price
	product.price_value = float(price)
	product.currency = "USD"
	product.product_type = product_type
	return product


## Initiate a purchase
func purchase(product_id: String) -> bool:
	if not _products.has(product_id):
		purchase_failed.emit(product_id, "Product not found")
		return false
	var product: IAPProduct = _products[product_id]
	# STUB: In Phase 7:
	# if OS.get_name() == "Android":
	#     GooglePlayBilling.purchase(product_id, product.product_type)
	# elif OS.get_name() == "iOS":
	#     StoreKit.purchase(product_id)
	_pending_purchase = product_id
	# Simulate success after a moment
	_simulate_purchase(product)
	return true


func _simulate_purchase(product: IAPProduct) -> void:
	await get_tree().create_timer(0.5).timeout
	var receipt: String = "stub_receipt_%s_%d" % [product.id, Time.get_ticks_msec()]
	purchase_successful.emit(product, receipt)
	_pending_purchase = ""


## Restore previous purchases
func restore_purchases() -> void:
	# STUB: In Phase 7:
	# if OS.get_name() == "iOS":
	#     StoreKit.restore_completed_transactions()
	# elif OS.get_name() == "Android":
	#     GooglePlayBilling.query_purchases("inapp")
	pass


## Get a product by ID
func get_product(product_id: String) -> IAPProduct:
	return _products.get(product_id)


## Check if user owns a non-consumable
func is_owned(product_id: String) -> bool:
	if not _products.has(product_id):
		return false
	# STUB: In Phase 7, check persistent storage
	# return OS.get_name() == "Android" ? GooglePlayBilling.has_purchase(product_id) : false
	return false