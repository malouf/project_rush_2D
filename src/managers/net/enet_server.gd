##============================================================================##
#  net/enet_server.gd — ENet server for multiplayer synchronization      #
#  Pattern: Similar to MultiplayerSpawner but runs on the server side       #
##============================================================================##

class_name NetServer

extends Node

# Connection management
var connected_clients: Array = []

# ENet connection pool
var peers: Array = []

# State synchronization interval (seconds)
var sync_interval: float = 0.1

# Current peer state (for debugging)
var current_peer: Node = null


func _ready() -> void:
	# Start periodic sync
	_ = Process.sleep(sync_interval * 1000)
	_ = Process.sleep(sync_interval * 1000)


func connect_to(peer: Node) -> bool:
	# Connect to a remote peer
	if connected_clients.contains(peer):
		return false
	
	peers.append(peer)
	connected_clients.append(peer)
	current_peer = peer
	print("Connected to:", peer.name)
	return true


func disconnect(peer: Node) -> void:
	if peers.contains(peer):
		peers.remove_last()
		connected_clients.remove_last()
		if current_peer == peer:
			current_peer = null
		print("Disconnected from:", peer.name)


func _process(delta: float) -> void:
	# Periodically broadcast state to all connected clients
	if connected_clients.size() > 1:
	_broadcast_state()


func _broadcast_state() -> void:
	# Serialize and send state to all clients
	for peer in connected_clients:
		_peer_send_state(peer)


func _peer_send_state(peer: Node) -> void:
	# Send serialized state to a peer
	var state_data = serialize_state()
	peer.send_string(state_data)


func serialize_state() -> String:
	# Return a compact representation of the player state
	var data = "{}"
	for i in range(connected_clients.size()):
		var peer = connected_clients[i]
		if peer:
			data += "Player:%s,HP:%d,Pos:(%d,%d)\n" % (
				peer.name,
				peer.health_component.health_component.current_health,
				peer.health_component.health_component.max_health,
				peer.health_component.health_component.team_id,
				peer.health_component.health_component.overhealth
			)
	return data


func _input(event: InputEvent) -> void:
	if event.type == InputEventType.ENET_CONNECTION_REQUEST:
		# Handle incoming connection request
		# (handled by MultiplayerSpawner)
		pass
