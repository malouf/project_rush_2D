##============================================================================##
#  gamecenter_interface.gd — Apple Game Center (stub)                          #
#  Adapted from: Document "Services Sociaux Natifs"                          #
##============================================================================##

class_name GameCenterInterface
extends Node

signal auth_success(player_id: String, display_name: String, token: String)
signal auth_failed(error_code: int, message: String)
signal sign_out_completed

var is_authenticated: bool = false
var player_id: String = ""
var display_name: String = ""

func authenticate() -> void:
	if not OS.has_feature("ios"):
		auth_failed.emit(-1, "Game Center only available on iOS")
		return

	# In Phase 7, use godot-ios-plugins:
	# GameCenterPlugin.authenticate_local_player()
	# On success:
	# player_id = GameCenterPlugin.get_local_player_id()
	# display_name = GameCenterPlugin.get_local_player_name()
	# token = GameCenterPlugin.get_sc_player_id_token()

	# Stub:
	is_authenticated = true
	player_id = "stub_gc_%d" % randi()
	display_name = "Gamer"
	token = "stub_gamecenter_token"
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
