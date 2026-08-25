##============================================================================##
#  ad_manager.gd — Ad manager (AdMob / Unity Ads / ironSource)                   #
#  Pattern: Singleton autoload for interstitial/ rewarded video                #
##============================================================================##

class_name AdManager
extends Node

signal ad_loaded(ad_type: String)
signal ad_failed(ad_type: String, error: String)
signal ad_shown(ad_type: String)
signal ad_closed(ad_type: String)
signal rewarded_video_completed(reward: Dictionary)

var _initialized: bool = false
var _ad_provider: String = "stub"  # "admob", "unity", "ironsource", "stub"
var _interstitial_ready: bool = false
var _rewarded_ready: bool = false
var _last_reward: Dictionary = {}


func _ready() -> void:
	# Initialize ad provider based on platform
	# In Phase 7, call real SDK init:
	# if OS.get_name() == "Android":
	#     _ad_provider = "admob"
	#     AdMob.initialize("YOUR_APP_ID")
	# elif OS.get_name() == "iOS":
	#     _ad_provider = "unity"
	#     UnityAds.initialize("YOUR_GAME_ID")
	# else:
	#     _ad_provider = "stub"
	_ad_provider = "stub"
	_initialized = true


## Load an interstitial ad
func load_interstitial(ad_id: String = "default") -> void:
	# STUB: In Phase 7, call SDK
	_interstitial_ready = true
	ad_loaded.emit("interstitial")


## Show an interstitial ad
func show_interstitial(ad_id: String = "default") -> bool:
	if not _interstitial_ready:
		return false
	# STUB: In Phase 7, call SDK
	# var result = await AdMob.show_interstitial_async()
	# if result:
	#     ad_shown.emit("interstitial")
	#     ad_closed.emit("interstitial")
	#     return true
	ad_shown.emit("interstitial")
	ad_closed.emit("interstitial")
	return true


## Load a rewarded video
func load_rewarded_video(ad_id: String = "default") -> void:
	# STUB: In Phase 7, call SDK
	_rewarded_ready = true
	ad_loaded.emit("rewarded")


## Show a rewarded video and return reward
func show_rewarded_video(ad_id: String = "default") -> bool:
	if not _rewarded_ready:
		return false
	# STUB: In Phase 7, call SDK
	# var result = await AdMob.show_rewarded_video_async()
	# if result:
	#     rewarded_video_completed.emit(result.reward)
	#     return true
	rewarded_video_completed.emit({"coins": 100, "gems": 5})
	return true


## Check if an ad is ready
func is_interstitial_ready() -> bool:
	return _interstitial_ready


func is_rewarded_ready() -> bool:
	return _rewarded_ready


## Show a banner ad (for mobile)
func show_banner(ad_id: String = "default") -> void:
	# STUB: In Phase 7, call SDK
	pass


## Hide banner
func hide_banner() -> void:
	# STUB: In Phase 7, call SDK
	pass


## Skip ad (for testing)
func skip_ad() -> void:
	ad_closed.emit("interstitial")