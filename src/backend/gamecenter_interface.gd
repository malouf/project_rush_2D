##============================================================================##
#  gamecenter_interface.gd — Apple Game Center interface                          #
#  Phase 7: Backend - iOS platform services                                     #
##============================================================================##

class_name GameCenterInterface
extends Node

signal authenticated(player: Dictionary)
signal authentication_failed(error: String)
signal achievement_unlocked(achievement_id: String)
signal leaderboard_submitted(leaderboard_id: String, score: int)
signal match_started(match: Dictionary)
signal match_ended(match: Dictionary)

var _is_authenticated: bool = false
var _player_id: String = ""
var _player_alias: String = ""
var _player_avatar: Texture2D = null


func _ready() -> void:
	# STUB: Phase 7 - use Apple GameKit on iOS
	# GameCenter.authenticate()
	pass


## Authenticate the local player
func authenticate() -> void:
	# STUB: In Phase 7:
	# GameCenter.authenticate()
	# Simulate success
	_is_authenticated = true
	_player_id = "GC_player_123"
	_player_alias = "Player"
	authenticated.emit({
		"player_id": _player_id,
		"alias": _player_alias
	})


## Check if player is authenticated
func is_authenticated() -> bool:
	return _is_authenticated


## Get player info
func get_player_id() -> String:
	return _player_id


func get_player_alias() -> String:
	return _player_alias


## Unlock achievement
func unlock_achievement(achievement_id: String) -> void:
	if not _is_authenticated:
		return
	# STUB: In Phase 7:
	# GameCenter.submit_achievement(achievement_id, 100.0)
	achievement_unlocked.emit(achievement_id)


## Submit score to leaderboard
func submit_score(leaderboard_id: String, score: int) -> void:
	if not _is_authenticated:
		return
	# STUB: In Phase 7:
	# GameCenter.submit_score(leaderboard_id, score)
	leaderboard_submitted.emit(leaderboard_id, score)


## Show Game Center UI
func show_game_center() -> void:
	if not _is_authenticated:
		return
	# STUB: In Phase 7:
	# GameCenter.show_game_center()
	pass


## Show achievements
func show_achievements() -> void:
	if not _is_authenticated:
		return
	# STUB: In Phase 7:
	# GameCenter.show_achievements()
	pass


## Show leaderboard
func show_leaderboard(leaderboard_id: String) -> void:
	if not _is_authenticated:
		return
	# STUB: In Phase 7:
	# GameCenter.show_leaderboard(leaderboard_id)
	pass


## Find match (turn-based or real-time)
func find_match(match_type: String = "real-time") -> void:
	if not _is_authenticated:
		return
	# STUB: In Phase 7:
	# GameCenter.find_match(match_type)
	match_started.emit({"type": match_type, "id": "stub_match_123"})


## End match and report results
func end_match(match: Dictionary, results: Array) -> void:
	if not _is_authenticated:
		return
	# STUB: In Phase 7:
	# GameCenter.end_match(match, results)
	match_ended.emit(match)


func _on_authentication_complete(player: Dictionary) -> void:
	_is_authenticated = true
	_player_id = player.get("player_id", "")
	_player_alias = player.get("alias", "")
	authenticated.emit(player)


func _on_authentication_failed(error: String) -> void:
	authentication_failed.emit(error)