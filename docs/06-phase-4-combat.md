# Phase 4: Combat System & Lag Compensation

## Goal
Implement component-based combat (Health, HurtBox2D, HitBox2D), DamagePayload
resource, and server-side lag compensation for hitscan weapons.

## Adapted from
- **PlaneShooter** `player.gd` — group-based hit detection, health reduction pattern
- **multiplayer_bomber** `player.gd` — `@export var stunned: bool` server-authoritative state
- **Godot docs** MultiplayerSynchronizer — property sync for `health`, `stunned`
- **isometric demo** — Area2D-based collision detection

## Component Architecture

### HealthComponent (src/components/health_component.gd)
```gdscript
class_name HealthComponent extends Node

signal health_changed(old_value: int, new_value: int, overhealth: int)
signal died()
signal shield_broken()

@export var max_health: int = 200
@export var armor: int = 50
var current_health: int
var overhealth: int = 0
var is_alive: bool = true

func _ready():
    current_health = max_health

func take_damage(amount: int, damage_type: StringName, critical: bool = false) -> int:
    var damage = amount
    # Overhealth absorbs first
    if overhealth > 0:
        var absorbed = min(overhealth, damage)
        overhealth -= absorbed
        damage -= absorbed
    # Armor reduction (flat, unless critical ignores armor)
    if not critical and armor > 0:
        damage = max(1, damage - armor)
    current_health = max(0, current_health - damage)
    emit_signal("health_changed", current_health + damage, current_health, overhealth)
    if current_health <= 0 and is_alive:
        is_alive = false
        emit_signal("died")
    return damage

func heal(amount: int) -> void:
    current_health = min(max_health, current_health + amount)

func apply_overhealth(amount: int, duration: float) -> void:
    overhealth += amount

func apply_stun(duration: float) -> void:
    get_parent().get_node("MovementFSM").enter_stun()
```

### HurtBox2D (src/components/hurtbox_component.gd)
```gdscript
class_name HurtBox2D extends Area2D

@export var defense_multiplier: float = 1.0
@export var team_id: int = 0
var invulnerable: bool = false: set = set_invulnerable

func _ready():
    connect("area_entered", _on_area_entered)

func _on_area_entered(area: Area2D) -> void:
    if area is HitBox2D and not invulnerable:
        var hitbox = area as HitBox2D
        if hitbox.team_id != team_id:
            var payload = hitbox.create_payload(self.global_position)
            var health = get_parent().get_node("HealthComponent") as HealthComponent
            var actual_damage = health.take_damage(
                payload.amount, payload.type, payload.is_critical)
            # Emit hit feedback via EventBus
            EventBus.player_damaged.emit(get_parent(), actual_damage, payload.is_critical)

func set_invulnerable(value: bool) -> void:
    invulnerable = value
    modulate = Color(1, 1, 1, 0.5) if value else Color(1, 1, 1, 1)
```

### HitBox2D (src/components/hitbox_component.gd)
```gdscript
class_name HitBox2D extends Area2D

@export var damage: int = 50
@export var damage_type: StringName = "bullet"
@export var knockback: Vector2 = Vector2.ZERO
@export var is_hitscan: bool = true
@export var team_id: int = 0

func create_payload(hit_position: Vector2) -> DamagePayload:
    var payload = DamagePayload.new()
    payload.shooter_id = team_id
    payload.amount = damage
    payload.type = damage_type
    payload.knockback = knockback
    payload.is_critical = false
    payload.hit_position = hit_position
    payload.timestamp = Time.get_ticks_msec()
    return payload
```

### DamagePayload (src/core/damage_payload.gd)
```gdscript
class_name DamagePayload extends Resource

var shooter_id: int
var amount: int
var type: StringName
var knockback: Vector2
var is_critical: bool
var hit_position: Vector2
var timestamp: int  # milliseconds
```

## Hit Registration Flow (Hitscan)

### 1. Client fires (prediction — immediate visual feedback)
```gdscript
# On local hero
func fire():
    var ray_start = global_position
    var ray_end = ray_start + aim_direction * weapon_range
    var space_state = get_world_2d().direct_space_state
    var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
    query.collision_mask = COLLISION_MASK_HURTBOX  # Only hit hurtboxes
    var result = space_state.intersect_ray(query)
    if result:
        var payload = create_payload(result.position)
        # Show muzzle flash, hit effect immediately
        EventBus.screen_shake_requested.emit(Vector2(5, 5), 0.1, Tween.TRANS_SINE)
        # Send to server for validation
        _server_validate_hit.rpc_id(1, result.collider.get_path(), aim_direction, result.position)
```

### 2. Server validates (authoritative)
```gdscript
@rpc("any_peer", "reliable")
func _server_validate_hit(target_path: NodePath, aim_dir: Vector2, hit_pos: Vector2):
    var shooter_id = multiplayer.get_remote_sender_id()
    var target = get_node(target_path) as Node2D
    if target == null or not _is_valid_target(shooter_id, target):
        return  # No valid target — reject

    # Lag compensation: rewind target position
    var shooter = get_tree().get_nodes_in_group("heroes")[shooter_id - 1]
    var latency = _get_peer_latency(shooter_id)
    var compensated_pos = _lag_compensation.get_position_at(
        target, Time.get_ticks_msec() - latency)

    # Verify hit at compensated position
    var predicted_hit_pos = compensated_pos + aim_dir * weapon_range
    if compensated_pos.distance_squared_to(hit_pos) > HIT_TOLERANCE_SQUARED:
        return  # Outside tolerance — reject

    # Apply damage authoritatively
    var payload = create_payload(hit_pos)
    target.get_node("HealthComponent").take_damage.rpc(
        payload.amount, payload.type, payload.is_critical)
```

### 3. Server applies + broadcasts result
- `HealthComponent.take_damage()` is an `@rpc("call_local")` — runs on all clients
- Broadcasts `EventBus.player_damaged` to trigger hit markers, health bar updates
- Broadcasts `EventBus.screen_shake_requested` for camera feedback

## Lag Compensation (src/combat/lag_compensation.gd)
- Server maintains circular buffer of `PlayerSnapshot{tick, position, velocity, state}` per player
- Buffer depth: 500ms at 60 Hz = 30 snapshots
- On hitscan fire: server rewinds target to `shooter_tick - latency_ticks`
- Checks raycast intersection at compensated past position
- Restores all snapshots after processing (no permanent rewind)

```gdscript
class_name LagCompensation extends Node

class PlayerSnapshot:
    var tick: int
    var position: Vector2
    var velocity: Vector2
    var is_alive: bool

# Ring buffer: peer_id -> array of snapshots (max 30)
var _snapshots: Dictionary = {}

func record_snapshot(peer_id: int, tick: int, pos: Vector2, vel: Vector2) -> void:
    var snap = PlayerSnapshot.new()
    snap.tick = tick
    snap.position = pos
    snap.velocity = vel
    snap.is_alive = true
    if not _snapshots.has(peer_id):
        _snapshots[peer_id] = []
    _snapshots[peer_id].push_back(snap)
    if _snapshots[peer_id].size() > 30:
        _snapshots[peer_id].pop_front()

func get_position_at(peer_id: int, tick: int) -> Vector2:
    var buffer = _snapshots.get(peer_id, [])
    # Binary search for closest tick <= requested
    for i in range(buffer.size() - 1, -1, -1):
        if buffer[i].tick <= tick:
            return buffer[i].position
    return Vector2.ZERO  # No data — reject hit
```

## MultiplayerSynchronizer for Health State
```gdscript
# On Hero scene's MultiplayerSynchronizer
# Replication config: health (reliable), is_alive (reliable), stunned (reliable)
# Position/velocity: unreliable, high frequency, handled by client prediction
```

## GUT Tests for Phase 4
- `test_health_component.gd`: damage application, armor reduction, overhealth absorption, death threshold
- `test_damage_payload.gd`: construction, field integrity, RPC-compatible
- `test_hurtbox_teams.gd`: same-team hits rejected, cross-team processed
- `test_hitbox_detection.gd`: range detection, knockback application
- `test_lag_compensation.gd`: snapshot buffer, rewind correctness, no past-hit false positives
- `test_armor_overhealth.gd`: verify overhealth absorbs before armor, critical bypasses armor
