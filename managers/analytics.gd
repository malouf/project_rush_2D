##============================================================================##
#  analytics.gd — Analytics facade (GameAnalytics/Firebase)                    #
#  Adapted from: Document "Telemétrie" section                                #
##============================================================================##

class_name Analytics
extends Node

## Settings
var enabled: bool = true
var _buffer: Array[Dictionary] = []
var _flush_interval: float = 5.0  # seconds
var _event_count: int = 0

## Backend stubs (replace with real SDK in Phase 7)
var _game_analytics_initialized: bool = false
var _firebase_initialized: bool = false

func _ready() -> void:
	_flush_timer()
	if not enabled:
		set_process(false)

func _process(delta: float) -> void:
	if _event_count >= 10:
		_flush_buffer()

func _flush_timer() -> void:
	var timer = Timer.new()
	timer.wait_time = _flush_interval
	timer.timeout.connect(_flush_buffer)
	add_child(timer)
	timer.start()

func track_event(name: String, params: Dictionary = {}) -> void:
	if not enabled:
		return
	_buffer.append({
		"event": name,
		"params": params,
		"timestamp": Time.get_ticks_msec(),
	})
	_event_count += 1
	if _event_count >= 10:
		_flush_buffer()

func _flush_buffer() -> void:
	if _buffer.is_empty():
		return
	if _game_analytics_initialized:
		# GameAnalytics.NewDesignEvent(_buffer[0]["event"], _buffer[0]["params"])
		pass
	if _firebase_initialized:
		# Firebase.Analytics.log_event(_buffer[0]["event"], _buffer[0]["params"])
		pass
	_buffer.clear()
	_event_count = 0

func track_match_start(mode: String) -> void:
	track_event("match_start", {"mode": mode})

func track_match_end(winner: int, duration: float) -> void:
	track_event("match_end", {"winner": winner, "duration": duration})

func track_death(hero_name: String, killer: String, weapon: String) -> void:
	track_event("player_death", {
		"hero": hero_name, "killer": killer, "weapon": weapon
	})

func track_churn() -> void:
	track_event("churn_check", {"session_time": Time.get_ticks_msec()})
