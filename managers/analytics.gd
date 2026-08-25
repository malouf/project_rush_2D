##============================================================================##
#  analytics.gd — Analytics facade (GameAnalytics/Firebase/Adjust)              #
#  Pattern: Buffered event queue with periodic flush                            #
##============================================================================##

class_name AnalyticsBase
extends Node

signal event_tracked(event_name: String, params: Dictionary)
signal flush_complete(count: int)

var enabled: bool = true
var _buffer: Array[Dictionary] = []
var _flush_interval: float = 5.0
var _event_count: int = 0
var _max_buffer_size: int = 50

var _game_analytics_initialized: bool = false
var _firebase_initialized: bool = false
var _adjust_initialized: bool = false


func _ready() -> void:
	_start_flush_timer()
	if not enabled:
		set_process(false)


func _start_flush_timer() -> void:
	var timer = Timer.new()
	timer.wait_time = _flush_interval
	timer.timeout.connect(_flush_buffer)
	timer.autostart = true
	add_child(timer)


func _process(delta: float) -> void:
	if _event_count >= _max_buffer_size:
		_flush_buffer()


## Track a generic event
func track_event(name: String, params: Dictionary = {}) -> void:
	if not enabled:
		return
	var event_data: Dictionary = {
		"event": name,
		"params": params,
		"timestamp": Time.get_ticks_msec(),
		"session_id": _get_session_id()
	}
	_buffer.append(event_data)
	_event_count += 1
	event_tracked.emit(name, params)
	
	if _event_count >= _max_buffer_size:
		_flush_buffer()


## Flush buffer to backend
func _flush_buffer() -> void:
	if _buffer.is_empty():
		return
	
	var events_to_send = _buffer.duplicate()
	_buffer.clear()
	_event_count = 0
	
	# GameAnalytics
	if _game_analytics_initialized:
		# for event in events_to_send:
		#     GameAnalytics.NewDesignEvent(event["event"], event["params"])
		pass
	
	# Firebase Analytics
	if _firebase_initialized:
		# for event in events_to_send:
		#     Firebase.Analytics.log_event(event["event"], event["params"])
		pass
	
	# Adjust
	if _adjust_initialized:
		# for event in events_to_send:
		#     Adjust.track_event(event["event"], event["params"])
		pass
	
	flush_complete.emit(events_to_send.size())


## Convenience tracking methods

func track_match_start(mode: String, map_name: String = "") -> void:
	track_event("match_start", {"mode": mode, "map": map_name})


func track_match_end(winner_team: int, duration_sec: float, mvp_player: String = "") -> void:
	track_event("match_end", {"winner_team": winner_team, "duration": duration_sec, "mvp": mvp_player})


func track_player_death(victim: String, killer: String, weapon: String, is_ai: bool = false) -> void:
	track_event("player_death", {
		"victim": victim, "killer": killer, "weapon": weapon, "ai": is_ai
	})


func track_skill_used(hero: String, skill_name: String, hits: int, damage: int) -> void:
	track_event("skill_used", {"hero": hero, "skill": skill_name, "hits": hits, "damage": damage})


func track_purchase(product_id: String, currency: String, price: float, is_test: bool = false) -> void:
	track_event("purchase", {"product": product_id, "currency": currency, "price": price, "test": is_test})


func track_ad_watched(ad_type: String, reward: Dictionary = {}) -> void:
	track_event("ad_watched", {"type": ad_type, "reward": reward})


func track_churn(session_time_sec: float) -> void:
	track_event("churn_check", {"session_time": session_time_sec})


func track_progression(event_name: String, current_value: int, max_value: int) -> void:
	track_event("progression", {"event": event_name, "current": current_value, "max": max_value})


func track_error(error_type: String, message: String, fatal: bool = false) -> void:
	track_event("error", {"type": error_type, "message": message, "fatal": fatal})


func set_user_id(user_id: String) -> void:
	# GameAnalytics.SetCustomUserId(user_id)
	pass


func set_dimension(dimension: int, value: String) -> void:
	# GameAnalytics.SetCustomDimension(dimension, value)
	pass


func _get_session_id() -> String:
	# Generate a session ID on first call
	if not has_meta("session_id"):
		var sid: String = str(randi()) + str(Time.get_ticks_msec())
		set_meta("session_id", sid)
		return sid
	return get_meta("session_id")


## Enable/disable analytics (GDPR opt-out)
func set_enabled(state: bool) -> void:
	enabled = state
	if state:
		set_process(true)
	else:
		_flush_buffer()
		set_process(false)