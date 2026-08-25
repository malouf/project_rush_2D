##============================================================================##
#  nakama_client.gd — Nakama multiplayer backend client                           #
#  Pattern: com.heroiclabs.nakama.gd (Godot 4.x SDK)                            #
#  Provides: matchmaking, lobbies, leaderboards, persistent storage            #
##============================================================================##

class_name NakamaClient
extends Node

signal authenticated(success: bool, message: String)
signal matchmaker_matched(ticket: String, match_id: String, server_ip: String, server_port: int)
signal matchmaker_ticket(ticket: String)
signal error(message: String)
signal friends_updated(friends: Array)
signal leaderboard_updated(scores: Array)

const DEFAULT_HOST = "127.0.0.1"
const DEFAULT_PORT = 7350
const SERVER = "https"

@export var host: String = DEFAULT_HOST
@export var port: int = DEFAULT_PORT
@export var server: String = SERVER
@export var api_key: String = "defaultkey"

var _client: Object = null
var _session: Object = null
var _socket: Object = null
var _matchmaker_ticket: String = ""

var is_authenticated: bool = false


func _ready() -> void:
	# Phase 7: Initialize with actual Nakama SDK
	# Replace the stubs below with real SDK calls:
	# _client = Nakama.create_client(api_key, host, port, server)
	pass


## Authenticate using device ID (anonymous login)
func authenticate_device() -> void:
	var device_id = _get_device_id()
	await _authenticate_async(device_id)


## Authenticate using username/password
func authenticate_email(email: String, password: String) -> void:
	await _authenticate_async(email + ":" + password)


func _authenticate_async(credential: String) -> void:
	# STUB: In Phase 7, use actual Nakama SDK:
	# var new_session = await _client.authenticate_custom_async(credential, "", true)
	# if new_session:
	#     _session = new_session
	#     is_authenticated = true
	#     authenticated.emit(true, "Authenticated as %s" % credential)
	# else:
	#     authenticated.emit(false, "Authentication failed")
	is_authenticated = true
	authenticated.emit(true, "Stub authenticated (Phase 7)")
	_establish_socket()


func _establish_socket() -> void:
	# STUB: In Phase 7:
	# _socket = _client.create_socket()
	# _socket.connect_async(_session)
	# _socket.matchmaker_matched.connect(_on_matchmaker_matched)
	# _socket.match_joined.connect(_on_match_joined)
	pass


## Join the matchmaker queue
func join_matchmaker(rating: int = 1000, min_players: int = 8, max_players: int = 8) -> void:
	if not is_authenticated:
		error.emit("Not authenticated")
		return
	# STUB: In Phase 7:
	# var result = await _client.add_matchmaker_async(_session, "*", min_players, max_players, [
	#     {"string": {"rating": str(rating)}}
	# ])
	# _matchmaker_ticket = result.ticket
	# matchmaker_ticket.emit(result.ticket)
	_matchmaker_ticket = "stub_ticket_%d" % Time.get_ticks_msec()
	matchmaker_ticket.emit(_matchmaker_ticket)
	# Simulate immediate match
	await get_tree().create_timer(2.0).timeout
	matchmaker_matched.emit(_matchmaker_ticket, "stub_match_%d" % randi(), "127.0.0.1", 10567)


func _on_matchmaker_matched(matched: Object) -> void:
	# STUB: Extract match ID and join
	matchmaker_matched.emit(matched.match_id, matched.match_id, host, port)


## Create a private lobby
func create_lobby(lobby_name: String, max_players: int = 8) -> void:
	# STUB: Nakama RT: _socket.send_matchCreate_async()
	matchmaker_matched.emit("lobby_" + lobby_name, "lobby_" + lobby_name, host, port)


## List online friends
func fetch_friends() -> void:
	if not is_authenticated:
		return
	# STUB: In Phase 7:
	# var result = await _client.list_friends_async(_session)
	# friends_updated.emit(result.friends)
	friends_updated.emit([])


## Submit a leaderboard score
func submit_score(leaderboard_id: String, score: int, metadata: Dictionary = {}) -> void:
	if not is_authenticated:
		return
	# STUB: In Phase 7:
	# await _client.write_leaderboard_record_async(_session, leaderboard_id, score, null, JSON.stringify(metadata))
	pass


## Fetch leaderboard
func fetch_leaderboard(leaderboard_id: String, limit: int = 100) -> void:
	if not is_authenticated:
		return
	# STUB: In Phase 7:
	# var result = await _client.list_leaderboard_records_async(_session, leaderboard_id, null, null, limit)
	# leaderboard_updated.emit(result.records)
	leaderboard_updated.emit([])


## Persist user data (battle pass, settings)
func save_user_data(storage_key: String, data: Dictionary) -> void:
	if not is_authenticated:
		return
	# STUB: In Phase 7:
	# var json_data = JSON.stringify(data)
	# await _client.write_storage_objects_async(_session, [
	#     NakamaStorageObject.new(storage_key, "player_data", json_data)
	# ])
	pass


## Load user data
func load_user_data(storage_key: String) -> Dictionary:
	# STUB: In Phase 7 - returns stored dict or empty
	return {}


func _get_device_id() -> String:
	# Use a persistent device ID
	var file = FileAccess.open("user://device.id", FileAccess.READ)
	if file:
		var device_id = file.get_line()
		file.close()
		if device_id.length() > 0:
			return device_id
	# Generate new
	var new_id = str(randi()) + str(Time.get_ticks_msec())
	var out_file = FileAccess.open("user://device.id", FileAccess.WRITE)
	if out_file:
		out_file.store_line(new_id)
		out_file.close()
	return new_id


func leave() -> void:
	is_authenticated = false
	matchmaker_ticket.emit("")
	_socket = null
	_session = null
