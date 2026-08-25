##============================================================================##
#  GameNetwork.gd — Network state management autoload                         #
#  Adapted from: multiplayer_bomber gamestate.gd                              #
##============================================================================##

class_name GameNetwork
extends Node

## Constants (from multiplayer_bomber pattern)
const DEFAULT_PORT = 10567
const MAX_PEERS = 8

## Signals
signal player_list_changed
signal connection_failed
signal connection_succeeded
signal server_disconnected
signal game_error(error_text: String)
signal match_starting
signal all_players_loaded

## State
var players: Dictionary = {}
var players_ready: Array[int] = []
var players_loaded: int = 0
var _peer: ENetMultiplayerPeer

## Player info (set before connecting)
var player_info: Dictionary = {
	"name": "Player",
	"team": 0,
	"hero": "assault",
}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## --- Public API ---

func host_game() -> Error:
	_peer = ENetMultiplayerPeer.new()
	var error = _peer.create_server(DEFAULT_PORT, MAX_PEERS)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = _peer
	players[1] = player_info
	player_list_changed.emit()
	return OK

func join_game(ip: String) -> Error:
	_peer = ENetMultiplayerPeer.new()
	var error = _peer.create_client(ip, DEFAULT_PORT)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = _peer
	return OK

func leave_game() -> void:
	if _peer:
		_peer.close()
	_peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	players_ready.clear()
	players_loaded = 0

func begin_game() -> void:
	assert(multiplayer.is_server(), "Only server can start game")
	match_starting.emit()
	# All peers load match scene
	_load_match_scene.rpc("res://scenes/world.tscn")

## --- Connection callbacks ---

func _on_peer_connected(id: int) -> void:
	_register_player.rpc_id(id, player_info)

func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		players.erase(id)
		player_list_changed.emit()

func _on_connected_ok() -> void:
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_list_changed.emit()
	connection_succeeded.emit()

func _on_connected_fail() -> void:
	leave_game()
	connection_failed.emit()

func _on_server_disconnected() -> void:
	leave_game()
	server_disconnected.emit()

## --- RPCs ---

@rpc("any_peer", "call_local", "reliable")
func _register_player(new_info: Dictionary) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	players[sender_id] = new_info
	player_list_changed.emit()

@rpc("call_local", "reliable")
func _load_match_scene(path: String) -> void:
	var error = get_tree().change_scene_to_file(path)
	if error != OK:
		game_error.emit("Failed to load match scene: %s" % path)
		return
	# Tell server we're loaded
	player_loaded.rpc_id(1)

@rpc("any_peer", "reliable")
func player_loaded() -> void:
	if not multiplayer.is_server():
		return
	players_loaded += 1
	if players_loaded == players.size():
		players_loaded = 0
		all_players_loaded.emit()
