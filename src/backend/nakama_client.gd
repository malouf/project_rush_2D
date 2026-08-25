##============================================================================##
#  nakama_client.gd — Nakama SDK facade                                        #
#  Adapted from: Document "Backend Social" + Nakama SDK docs                  #
##============================================================================##

class_name NakamaClient
extends Node

signal authenticated(success: bool, message: String)
signal matchmaker_result(match_id: String, server_ip: String, server_port: int)
signal error(message: String)

# Placeholder — real implementation uses com.heroiclabs.nakama.gd (Godot plugin)
var _client: Object = null
var _session: Object = null
var _socket: Object = null

var is_connected: bool = false

func authenticate(device_id: String) -> void:
	# In Phase 7, replace with actual Nakama SDK call:
	# _client = Nakama.create_client("defaultkey", "127.0.0.1", 7300, "https")
	# _session = await _client.authenticate_custom(device_id)
	# _socket = _client.create_socket()
	# _socket.connect_async()
	is_connected = true
	authenticated.emit(true, "Stub authenticated (Phase 7 placeholder)")

func add_matchmaker(mmr: int = 1000, min_count: int = 8, max_count: int = 8) -> String:
	# Stub — returns fake ticket
	if not is_connected:
		error.emit("Not authenticated")
		return ""
	return "stub_ticket_%d" % Time.get_ticks_msec()

func create_match() -> void:
	# Server-side match creation
	pass

func join_match(match_id: String) -> void:
	# Join existing match
	pass

func get_friends() -> Array:
	return []

func get_groups() -> Array:
	return []

func get_match_history(limit: int = 10) -> Array:
	return []

func save_battle_pass(passport: Dictionary) -> void:
	# Storage write via Nakama RPC
	pass

func load_battle_pass() -> Dictionary:
	return {"tier": 0, "xp": 0, "purchased": false, "rewards_claimed": []}

func save_match_result(result: Dictionary) -> void:
	# Persist match history
	pass

func leave() -> void:
	is_connected = false
	if _socket:
		_socket.close()
