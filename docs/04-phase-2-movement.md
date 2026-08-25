# Phase 2: Physical Foundations & Interpolation

## Goal
Implement `BaseHero` with isometric movement, physics/visual separation for 120 FPS,
and Node-based FSM for movement and combat states. Solo (single-player) — no
networking yet. Uses simple placeholder graphics (colored rectangle + arrow for direction).

## Adapted from
- **isometric demo** `goblin.gd` — cartesian to isometric transform, 8-direction animation
- **isometric demo** `dungeon.tscn` — YSort pattern, TileMap layers, `y_sort_origin`
- **multiplayer_bomber** `player.gd` — authority check pattern

## Isometric Map Setup (from `dungeon.tscn` pattern)
- TileMap layers: Floor, Walls, HighWalls — all with `y_sort_enabled = true`
- TileMap position offset: `Vector2(-64, -32)` (standard isometric offset)
- `layer_0/y_sort_origin = 32` (half of 64px tile height)
- Player placed under a `YSort` node that sorts against floor/wall tilemaps
- Z-ordering: Floor (z=0) < Player (z=0, YSorted) < HighWalls (z=1)

## BaseHero (src/core/base_hero.gd)

```gdscript
class_name BaseHero extends CharacterBody2D

const SPEED = 160.0  # pixels/second (from isometric demo MOTION_SPEED)

@export var hero_data: HeroData  # Resource with stats
@export var is_local_authority: bool = true

@onready var movement_fsm: MovementFSM = $MovementFSM
@onready var combat_fsm: CombatFSM = $CombatFSM

func _physics_process(delta: float) -> void:
    var motion = Vector2.ZERO
    # Isometric input (from goblin.gd pattern)
    motion.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    motion.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    motion.y /= 2  # Isometric foreshortening
    motion = motion.normalized() * SPEED

    if is_local_authority and not movement_fsm.is_stunned():
        velocity = motion
        movement_fsm.set_input(motion)
        move_and_slide()

    # Visual interpolation happens on child Sprite2D node (see below)
```

## Sprite Interpolation (src/components/interpolation.gd)
- Attached to **child** `Sprite2D` node (NOT to CharacterBody2D)
- Pattern:
```gdscript
extends Sprite2D

var _prev_position: Vector2

func _ready():
    _prev_position = position

func _physics_process(delta):
    _prev_position = get_parent().position

func _process(delta):
    # Factor based on remainder between physics and render frames
    var factor = Engine.get_physics_frames_to_process() * Engine.get_physics_process_delta() - delta
    factor = clamp(factor, 0.0, 1.0)
    position = lerp(_prev_position, get_parent().position, factor)
```
- Works alongside Godot 4's built-in `physics_interpolation = true` (project.godot)

## Node-Based FSM (from document: "Machines d'Etats Finis")

### MovementFSM (src/components/movement_fsm.gd)
```gdscript
class_name MovementFSM extends Node

enum State { IDLE, RUN, STUN }
var current_state: State = State.IDLE

func set_input(motion: Vector2) -> void:
    match current_state:
        State.IDLE:
            if motion.length() > 0.01:
                transition_to(State.RUN)
        State.RUN:
            if motion.length() <= 0.01:
                transition_to(State.IDLE)

func transition_to(state: State) -> void:
    current_state = state

func is_stunned() -> bool:
    return current_state == State.STUN

func enter_stun() -> void:
    transition_to(State.STUN)
    # Will be reset by combat system when stun expires
```

### CombatFSM (separate from MovementFSM — document: "decoupling stricte")
- States: `READY`, `CASTING`, `RELOADING`
- `class_name CombatFSM extends Node`
- Allows hero to reload while running (movement FSM and combat FSM are independent)

## Simple Placeholder Graphics (Phase 1 approach)
For Phase 2 (per user's "simple graphics for now"):
- Hero body: `ColorRect` with team color (red/blue, 32x48px)
- Direction indicator: `Sprite2D` with arrow texture (placeholder PNG: simple triangle)
- Movement animation: scale pulse on direction change (0.9→1.1→1.0)
- No animated sprites yet — defer to Phase 5+

## GUT Tests for Phase 2
- `test_movement_fsm.gd`: verify Idle→Run→Stun→Idle transitions, input routing
- `test_base_hero.gd`: verify isometric transform, velocity clamping
- `test_interpolation.gd`: verify sprite position lerps correctly between physics frames
