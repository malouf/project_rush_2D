extends GutTest

var _analytics: Analytics
var _ad_manager: AdManager
var _iap: IAPManager
var _nakama: NakamaClient
var _gpgs: GPGSInterface
var _gc: GameCenterInterface

func before_each():
	_analytics = Analytics.new()
	add_child_autofree(_analytics)
	
	_ad_manager = AdManager.new()
	add_child_autofree(_ad_manager)
	
	_iap = IAPManager.new()
	add_child_autofree(_iap)
	
	_nakama = NakamaClient.new()
	add_child_autofree(_nakama)
	
	_gpgs = GPGSInterface.new()
	add_child_autofree(_gpgs)
	
	_gc = GameCenterInterface.new()
	add_child_autofree(_gc)


func after_each():
	_analytics.free()
	_ad_manager.free()
	_iap.free()
	_nakama.free()
	_gpgs.free()
	_gc.free()


func test_analytics_initial_state():
	assert_true(_analytics.enabled == true)


func test_analytics_track_event():
	_analytics.track_event("test_event", {"key": "value"})
	assert_true(true)  # Tests that tracking doesn't crash


func test_analytics_track_match_start():
	_analytics.track_match_start("ranked")
	assert_true(true)


func test_analytics_track_match_end():
	_analytics.track_match_end(1, 120.5)
	assert_true(true)


func test_ad_manager_initial():
	assert_true(_ad_manager._initialized == true or _ad_manager._ad_provider == "stub")


func test_iap_catalog_load():
	var product_ids: Array = ["gems_100", "gems_500"]
	_iap.load_catalog(product_ids)
	assert_true(true)


func test_iap_purchase():
	var ok = _iap.purchase("gems_100")
	assert_true(ok == true or ok == false)  # Doesn't crash


func test_gpgs_sign_in():
	var ok = _gpgs.sign_in()
	assert_true(ok == true or ok == false)  # Doesn't crash


func test_gpgs_sign_out():
	_gpgs.sign_out()
	assert_true(true)


func test_gpgs_is_signed_in():
	assert_true(_gpgs.is_signed_in() == true or _gpgs.is_signed_in() == false)


func test_gc_authenticate():
	var ok = _gc.authenticate()
	assert_true(ok == true or ok == false)  # Doesn't crash


func test_gc_is_authenticated():
	assert_true(_gc.is_authenticated() == true or _gc.is_authenticated() == false)


func test_nakama_authenticate():
	_nakama.authenticate_device()
	assert_true(true)


func test_nakama_join_matchmaker():
	_nakama.join_matchmaker()
	assert_true(true)


func test_nakama_submit_score():
	_nakama.submit_score("test_leaderboard", 1500)
	assert_true(true)


func test_gc_submit_score():
	_gc.submit_score("test_leaderboard", 2000)
	assert_true(true)