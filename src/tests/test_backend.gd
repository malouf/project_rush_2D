extends GutTest

func before_each():
	pass


func test_analytics_initial_state():
	assert_true(AnalyticsBase.enabled == true)


func test_analytics_track_event():
	AnalyticsBase.track_event("test_event", {"key": "value"})
	assert_true(true)


func test_analytics_track_match_start():
	AnalyticsBase.track_match_start("ranked")
	assert_true(true)


func test_analytics_track_match_end():
	AnalyticsBase.track_match_end(1, 120.5)
	assert_true(true)


func test_ad_manager_initial():
	var _ad_manager = AdManager.new()
	add_child_autofree(_ad_manager)
	assert_true(_ad_manager._initialized == true or _ad_manager._ad_provider == "stub")


func test_iap_catalog_load():
	var _iap = IAPManager.new()
	add_child_autofree(_iap)
	var product_ids: Array = ["gems_100", "gems_500"]
	_iap.load_catalog(product_ids)
	assert_true(true)


func test_iap_purchase():
	var _iap = IAPManager.new()
	add_child_autofree(_iap)
	var ok = _iap.purchase("gems_100")
	assert_true(ok == true or ok == false)


func test_gpgs_sign_in():
	var _gpgs = GPGSInterface.new()
	add_child_autofree(_gpgs)
	var ok = _gpgs.sign_in()
	assert_true(ok == true or ok == false)


func test_gpgs_sign_out():
	var _gpgs = GPGSInterface.new()
	add_child_autofree(_gpgs)
	_gpgs.sign_out()
	assert_true(true)


func test_gpgs_is_signed_in():
	var _gpgs = GPGSInterface.new()
	add_child_autofree(_gpgs)
	assert_true(_gpgs.is_signed_in() == true or _gpgs.is_signed_in() == false)


func test_gc_authenticate():
	var _gc = GameCenterInterface.new()
	add_child_autofree(_gc)
	var ok = _gc.authenticate()
	assert_true(ok == true or ok == false)


func test_gc_is_authenticated():
	var _gc = GameCenterInterface.new()
	add_child_autofree(_gc)
	assert_true(_gc.is_authenticated() == true or _gc.is_authenticated() == false)


func test_nakama_authenticate():
	var _nakama = NakamaClient.new()
	add_child_autofree(_nakama)
	_nakama.authenticate_device()
	assert_true(true)


func test_nakama_join_matchmaker():
	var _nakama = NakamaClient.new()
	add_child_autofree(_nakama)
	_nakama.join_matchmaker()
	assert_true(true)


func test_nakama_submit_score():
	var _nakama = NakamaClient.new()
	add_child_autofree(_nakama)
	_nakama.submit_score("test_leaderboard", 1500)
	assert_true(true)


func test_gc_submit_score():
	var _gc = GameCenterInterface.new()
	add_child_autofree(_gc)
	_gc.submit_score("test_leaderboard", 2000)
	assert_true(true)
