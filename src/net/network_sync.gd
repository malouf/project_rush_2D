##============================================================================##
#  net/network_sync.gd — Synchronizes networked hero state                     #
#  Attaches to hero with MultiplayerSynchronizer                                #
##============================================================================##

class_name NetworkSync
extends Node

@export var sync_position: bool = true
@export var sync_velocity: bool = false
@export var sync_facing: bool = false

var _syncer: MultiplayerSynchronizer
var _hero: Node2D

func _ready() -> void:
	_hero = get_parent()
	_setup_synchronizer()


func _setup_synchronizer() -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	_syncer = MultiplayerSynchronizer.new()
	_syncer.name = "NetSync"
	_syncer.root_path = NodePath("..")
	_hero.add_child(_syncer)
	_syncer.set_visibility_update_mode(MultiplayerSynchronizer.VISIBILITY_UPDATE_MODE_ALWAYS)

	# Position sync
	if sync_position:
		_syncer.add_tracked_node(NodePath("../.."))
	_syncer.replication_interval = 0.05


## Sync transform to remote peers
@rpc("call_local", "reliable")
func sync_transform(pos: Vector2, facing: Vector2) -> void:
	if multiplayer.is_server():
		return  # Server doesn't need to receive its own transform
	if not is_authority:
		_hero.global_position = pos
