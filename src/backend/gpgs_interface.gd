##============================================================================##
#  gpgs_interface.gd — Google Play Games Services interface                       #
#  Phase 7: Backend - mobile platform services                                   #
##============================================================================##

class_name GPGSInterface
extends Node

signal signed_in
signal signed_out
signal sign_in_failed(error: String)
signal achievement_unlocked(achievement_id: String)
signal leaderboard_score_uploaded(leaderboard_id: String, score: int)
signal saved_game_written(name: String)
signal saved_game_loaded(name: String, data: Dictionary)
signal save_conflict(name: String, local: Dictionary, remote: Dictionary, callback: Callable)

var _is_signed_in: bool = false
var _player_id: String = ""
var _player_name: String = ""
var _save_data: Dictionary = {}


func _ready() -> void:
	# STUB: Phase 7 - use Godot Android plugin
	# GPGS.signIn.connect("sign_in_complete", _on_sign_in_complete)
	# GPGS.signIn.connect("sign_in_failed", _on_sign_in_failed)
	pass


## Sign in to Google Play Games
func sign_in() -> void:
	# STUB: In Phase 7:
	# GPGS.signIn()
	# Simulate immediate success
	_is_signed_in = true
	_player_id = "stub_player_id"
	_player_name = "Player"
	signed_in.emit()


## Sign out
func sign_out() -> void:
	_is_signed_in = false
	_player_id = ""
	_player_name = ""
	signed_out.emit()


## Check if user is signed in
func is_signed_in() -> bool:
	return _is_signed_in


## Get current player info
func get_player_id() -> String:
	return _player_id


func get_player_name() -> String:
	return _player_name


## Unlock an achievement
func unlock_achievement(achievement_id: String) -> void:
	if not _is_signed_in:
		return
	# STUB: In Phase 7:
	# GPGS.achievements.unlock(achievement_id)
	achievement_unlocked.emit(achievement_id)


## Increment achievement progress
func increment_achievement(achievement_id: String, steps: int) -> void:
	if not _is_signed_in:
		return
	# STUB: In Phase 7:
	# GPGS.achievements.increment(achievement_id, steps)
	pass


## Reveal a hidden achievement
func reveal_achievement(achievement_id: String) -> void:
	if not _is_signed_in:
		return
	# STUB: In Phase 7:
	# GPGS.achievements.reveal(achievement_id)
	pass


## Show achievements UI
func show_achievements() -> void:
	if not _is_signed_in:
		return
	# STUB: In Phase 7:
	# GPGS.achievements.show()
	pass


## Submit a leaderboard score
func submit_score(leaderboard_id: String, score: int) -> void:
	if not _is_signed_in:
		return
	# STUB: In Phase 7:
	# GPGS.leaderboards.submit(leaderboard_id, str(score))
	leaderboard_score_uploaded.emit(leaderboard_id, score)


## Show leaderboard UI
func show_leaderboard(leaderboard_id: String) -> void:
	if not _is_signed_in:
		return
	# STUB: In Phase 7:
	# GPGS.leaderboards.show(leaderboard_id)
	pass


## Save game data to cloud
func save_game(save_name: String, data: Dictionary) -> void:
	if not _is_signed_in:
		return
	# STUB: In Phase 7:
	# GPGS.snapshots.open(save_name).write(JSON.stringify(data))
	saved_game_written.emit(save_name)


## Load saved game data
func load_game(save_name: String) -> void:
	if not _is_signed_in:
		return
	# STUB: In Phase 7:
	# var snapshot = GPGS.snapshots.open(save_name)
	# var data = JSON.parse_string(snapshot.read())
	# saved_game_loaded.emit(save_name, data)
	var data: Dictionary = _save_data.get(save_name, {})
	saved_game_loaded.emit(save_name, data)


## Show saved games selection UI
func show_saved_games_ui() -> void:
	if not _is_signed_in:
		return
	# STUB: In Phase 7:
	# GPGS.snapshots.show()
	pass


func _on_sign_in_complete() -> void:
	_is_signed_in = true
	signed_in.emit()


func _on_sign_in_failed(error: String) -> void:
	sign_in_failed.emit(error)