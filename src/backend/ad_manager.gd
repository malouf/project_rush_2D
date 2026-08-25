##============================================================================##
#  ad_manager.gd — Rewarded ads interface (AdMob via Poing Studios)             #
#  Adapted from: Document "Monétisation AAA"                                   #
##============================================================================##

class_name AdManager
extends Node

signal rewarded_completed(reward_type: String, reward_amount: int)
signal ad_failed(error_code: int)
signal consent_updated(granted: bool)

enum RewardType {
	NANOS = 25,
	XP_BOOST = 3600,
	BATTLE_PASS_SKIP = 1,
}

var _consent_granted: bool = false
var _rewarded_ready: bool = false
var _daily_claim_count: int = 0
var _last_claim_date: String = ""

func _ready() -> void:
	if not _check_daily_limit():
		return
	# Initialize AdMob plugin (Poing Studios)
	# AdMobPlugin.init_ads()
	# AdMobPlugin.load_rewarded()

func request_consent() -> void:
	if OS.has_feature("android") or OS.has_feature("ios"):
		# UMP consent dialog
		# UMP.request_consent()
		pass
	else:
		_consent_granted = true
		consent_updated.emit(true)

func show_rewarded() -> bool:
	if not _consent_granted:
		ad_failed.emit(-1)
		return false
	if not _check_daily_limit():
		EventBus.ui_screen_requested.emit("reward_limit", {})
		return false
	if not _rewarded_ready:
		ad_failed.emit(-2)
		return false

	# AdMobPlugin.show_rewarded()
	# On completion callback:
	# rewarded_completed.emit("nanos", RewardType.NANOS)
	_daily_claim_count += 1
	_save_daily_count()
	return true

func _check_daily_limit() -> bool:
	var today = Time.get_date_string_from_system()
	if _last_claim_date != today:
		_last_claim_date = today
		_daily_claim_count = 0
	return _daily_claim_count < 3  # 3 rewarded ads per day max

func _save_daily_count() -> void:
	var config = ConfigFile.new()
	config.set_value("ads", "last_claim_date", _last_claim_date)
	config.set_value("ads", "daily_count", _daily_claim_count)
	config.save("user://ad_limit.cfg")

func _load_daily_count() -> void:
	var config = ConfigFile.new()
	if config.load("user://ad_limit.cfg") == OK:
		_last_claim_date = config.get_value("ads", "last_claim_date", "")
		_daily_claim_count = config.get_value("ads", "daily_count", 0)
