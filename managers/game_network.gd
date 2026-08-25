##============================================================================##
#  GameNetwork.gd — Network state management autoload                         #
#  Pattern: multiplayer_bomber gamestate.gd + isometric networking            #
#  Server-authoritative with client input prediction                         #
##============================================================================##

class_name GameNetworkBase
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
var _peer: ENetMultiplayerPeer = null

## Player info (set before connecting)
var player_info: Dictionary = {
	"name": "Player",
	"team": 0,
	"hero": "assault",
	"starting_pos": Vector2.ZERO,
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
	multiplayer.multiplayer_peer = null
	players.clear()
	players_ready.clear()
	players_loaded = 0

func begin_game() -> void:
	assert(multiplayer.is_server(), "Only server can start game")
	match_starting.emit()
	rpc_id(1, "client_load_match", "res://scenes/match/match.tscn")
	client_load_match("res://scenes/match/match.tscn")

## --- Connection callbacks ---

func _on_peer_connected(id: int) -> void:
	rpc_id(id, "_register_player", player_info)

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
func client_load_match(path: String) -> void:
	var error = get_tree().change_scene_to_file(path)
	if error != OK:
		game_error.emit("Failed to load match scene: %s" % path)
		return
	rpc_id(1, "player_loaded")

@rpc("any_peer", "reliable")
func player_loaded() -> void:
	if not multiplayer.is_server():
		return
	players_loaded += 1
	if players_loaded == players.size():
		players_loaded = 0
		all_players_loaded.emit()

@rpc("call_local", "reliable")
func set_player_info(info: Dictionary) -> void:
	var pid = multiplayer.get_unique_id()
	if not players.has(pid):
		players[pid] = info
	player_list_changed.emit()

@rpc("call_local", "reliable")
func request_spawn(hero_type: String, pos: Vector2) -> void:
	if multiplayer.is_server():
		var hero_node = spawn_hero(hero_type, pos)
		if hero_node:
			rpc("%s_spawned" % hero_type, hero_node.get_path())

@rpc("any_peer", "reliable")
func _spawned_hero(hero_node_path: NodePath) -> void:
	var hero = get_node_or_null(hero_node_path)
	if hero:
		hero.modulate = Color(1, 1, 1, 1)

## --- Server-side spawn logic ---

func spawn_hero(hero_type: String, pos: Vector2) -> Node:
	var hero_path: String = "res://scenes/%s/%s.tscn" % [hero_type, hero_type]
	var hero_node = get_tree().get_nodes_in_group("world")[0].get_node_or_null(hero_type)
	if hero_node:
		hero_node.global_position = pos
		return hero_node
	return null
