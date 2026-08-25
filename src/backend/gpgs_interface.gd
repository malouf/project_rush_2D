##============================================================================##
#  gpgs_interface.gd — Google Play Games Services v2 (stub)                    #
#  Adapted from: Document "Services Sociaux Natifs"                           #
##============================================================================##

class_name GPGSInterface
extends Node

signal auth_success(player_id: String, display_name: String, token: String)
signal auth_failed(error_code: int, message: String)
signal sign_out_completed

var is_authenticated: bool = false
var player_id: String = ""
var display_name: String = ""

func authenticate() -> void:
	if not OS.has_feature("android"):
		auth_failed.emit(-1, "GPGS only available on Android")
		return

	# In Phase 7, use godot-play-game-services plugin:
	# PlayGames.local_player_authenticate()
	# On success:
	# player_id = PlayGames.get_local_player_id()
	# display_name = PlayGames.get_local_player_name()
	# token = PlayGames.get_server_auth_code()

	# Stub:
	is_authenticated = true
	player_id = "stub_player_%d" % randi()
	display_name = "Anonymous"
	token = "stub_token_%d" % Time.get_ticks_msec()
	auth_success.emit(player_id, display_name, token)

func sign_out() -> void:
	is_authenticated = false
	player_id = ""
	display_name = ""
	sign_out_completed.emit()

func is_authenticated_player() -> bool:
	return is_authenticated

func get_player_id() -> String:
	return player_id

func get_display_name() -> String:
	return display_name
