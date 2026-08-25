# Phase 3: Network Infrastructure & Predictive Netcode

## Goal
Build authoritative server architecture with client-side prediction and server
reconciliation. Adapted from multiplayer_bomber patterns + AAA industry standard netcode.

## Adapted from
- **multiplayer_bomber** `gamestate.gd` — ENet setup, player registration, world loading
- **multiplayer_bomber** `player.gd` — authority checks, synced_position pattern
- **Godot docs** High-Level Multiplayer — RPC annotations, security patterns
- **Godot docs** MultiplayerSynchronizer — property sync, visibility culling

## ENet Configuration (managers/game_network.gd)
```gdscript
# Adapted from gamestate.gd pattern
const DEFAULT_PORT = 10567
const MAX_PEERS = 8

func host_game() -> void:
    var peer = ENetMultiplayerPeer.new()
    var error = peer.create_server(DEFAULT_PORT, MAX_PEERS)
    multiplayer.multiplayer_peer = peer

func join_game(ip: String) -> void:
    var peer = ENetMultiplayerPeer.new()
    var error = peer.create_client(ip, DEFAULT_PORT)
    multiplayer.multiplayer_peer = peer
```

## Lobby Handshake (from gamestate.gd)
1. Client connects to server → `peer_connected(id)` signal
2. Server sends `register_player.rpc_id(id, player_info)` with lobby config
3. Client responds with `client_ready` RPC
4. Server counts `players_ready`; when all 8 → `load_world.rpc()` (call_local, reliable)
5. Each client calls `LobbyManager.player_loaded.rpc_id(1)` on scene load complete
6. Server verifies all loaded, then calls `GameManager.start_game()`

## Client-Side Prediction (src/network/client_prediction.gd)

Based on multiplayer_bomber `player.gd` authority pattern + AAA standard CSP:

```gdscript
# InputFrame — structure sent to server every physics tick
class InputFrame:
    var tick: int
    var input_vector: Vector2
    var actions: Dictionary  # {ability_1: true, jump: false}

# On local player (client-side prediction)
func _physics_process(delta):
    if is_local_authority:
        var frame = _build_input_frame(tick_counter)
        _pending_inputs[frame.tick] = frame
        # Apply input IMMEDIATELY (prediction)
        _apply_input(frame)
        # Send to server (unreliable for movement, reliable for actions)
        _send_input.rpc_id(1, frame.tick, frame.input_vector, frame.actions)

    # ALWAYS run local physics (even clients run physics to predict opponents)
    move_and_slide()
```

## Server Reconciliation (src/network/server_reconciliation.gd)

```gdscript
# Called when server authoritative state arrives
func _on_server_state(tick: int, server_pos: Vector2, server_vel: Vector2):
    if tick in _pending_inputs:
        var error_sq = server_pos.distance_squared_to(_predicted_positions[tick])
        if error_sq > RECONCILIATION_THRESHOLD_SQUARED:
            # Significant discrepancy — rewind and replay
            global_position = server_pos
            velocity = server_vel
            # Re-simulate all unacked inputs in order
            for pending_tick in range(tick + 1, _current_tick):
                if pending_tick in _pending_inputs:
                    _apply_input(_pending_inputs[pending_tick])
                    move_and_slide()
        # Clear processed input
        _pending_inputs.erase(tick)
```

## MultiplayerSynchronizer Integration (from Godot docs)

On each hero's `MultiplayerSynchronizer` node:
- `replication_config`: syncs `position`, `velocity` (unreliable, high frequency)
- `replication_interval = 1/30.0` (every other physics tick — balanced bandwidth)
- Visibility: `add_visibility_filter()` for team-based + distance-based culling (50 tiles)
- Authority pattern (from multiplayer_bomber `player.gd:22`):
```gdscript
# On hero spawn, server sets multiplayer authority to owning client
hero.set_multiplayer_authority(spawn_peer_id)
```

## Network Channels (from Godot docs)
- **Channel 0 (unreliable)**: position/velocity updates (spam, loss-tolerant)
- **Channel 1 (reliable)**: state events (spawn, death, ability cast)
- **Channel 2 (reliable)**: chat messages
- Channels are independent — chat ACK doesn't block movement packets

## RPC Security (from Godot docs "Secure multiplayer design")
- **All** RPC arguments validated server-side before applying
- Never trust client-reported position, health, or cooldown timers
- Server is source of truth for: position, health, match state, objective progress
- Client sends **input** → server validates → simulates → sends back state

## Dedicated Server Mode
- Headless launch: `godot --headless --path project_rush_2d.pck`
- Export preset "Dedicated Server" in `export/export_presets.cfg`
- No rendering code executes: `if not OS.has_feature("dedicated_server"):` guard
- Connects to Nakama for auth, then accepts ENet clients on configured port

## GUT Tests for Phase 3
- `test_lobby_handshake.gd`: verify all_players_loaded fires after N clients ready
- `test_client_prediction.gd`: verify input buffering, position consistency on reconciliation
- `test_reconciliation.gd`: verify threshold triggers rewind, re-simulation correctness
- `test_network_channels.gd`: verify channel separation (chat doesn't block movement)
