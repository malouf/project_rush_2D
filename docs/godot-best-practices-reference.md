# Godot 4 Best Practices Reference

This document consolidates all Godot best practices verified against official documentation
and reference projects (`librerama`, `PlaneShooter`, `multiplayer_bomber`, `isometric demo`)
applied to Project Rush 2D.

---

## 1. Project Organization

### File & Folder Naming
- Use **snake_case** for folders and GDScript files (prevents case sensitivity issues on export)
- Use **PascalCase** for C# scripts (matches class naming)
- Use **PascalCase** for node names (matches built-in Godot node casing)
- Keep third-party resources in top-level `addons/` folder
- Group assets close to scenes that use them (avoids asset database bloat)

**References**: [Godot Docs — Project Organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)

### Version Control
- **`.gitignore`**: exclude `.godot/` cache, `*.import/`, `godot_*.log`, `export.cfg`, `.editor/`
- **`.gitattributes`**: `* text=auto eol=lf` + Git LFS for `.png`, `.wav`, `.ttf`, `.scn`, `.tscn`, `.tres`
- **Case sensitivity**: Enable on Windows via `fsutil file setcasesensitiveinfo <path> enable`
- **Large assets**: Use Git LFS for binaries >1MB; commit text files (`.gd`, `.tscn` metadata) directly

**Adapted from**: [Godot Docs — VCS](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html), librerama `.gitignore`

### Ignoring Folders
- `.gdignore` on folders that should not be imported by Godot: `docs/`, `addons/`, `tests/`, `export/`
- Create via: `type nul > .gdignore` on Windows

---

## 2. Scene Organization (OOP Principles)

### Scene Independence
- **Scenes should have no external dependencies** — everything they need is internal
- If a scene must interact with external context, use **Dependency Injection**:
  1. **Signal connection**: Parent connects to child's signal — safe, but only for "respond" behavior
  2. **Method assignment**: Parent sets a method name for child to call
  3. **Callable property**: Parent assigns a `Callable` for child to invoke
  4. **Node reference**: Parent passes a Node reference
  5. **NodePath**: Parent passes a path (resolved at runtime)
- Use `_get_configuration_warnings()` in `@tool` scripts to surface missing dependencies in the editor

**Reference**: [Godot Docs — Scene Organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html)

### Root Tree Structure (from Godot Docs)
```
Node "Main" (main.gd)
├── Node2D/Node3D "World" (game_world.gd)
└── Control "GUI" (gui.gd)
```
- For networked games: keep player controllers in a separate branch from "world"
  to distinguish server-authoritative vs. client-relevant logic

### SOLID Principles in Godot
- **Single Responsibility**: Each node has one clear job
- **Open/Closed**: BaseHero is open for extension (subclass per hero), closed for modification
- **Liskov Substitution**: BotHero can replace Hero in any context
- **Interface Segregation**: Prefer small, focused interfaces over monolithic ones
- **Dependency Inversion**: High-level modules (match logic) should not depend on low-level (rendering)

---

## 3. Autoloads vs Regular Nodes

### Use Autoload for:
1. Data is tracked internally (singleton)
2. Must be globally accessible
3. Should exist in isolation (independent of any scene)

### Use Regular Nodes for:
1. Systems that modify other systems' data (use DI instead)
2. Transient or scene-specific logic
3. Anything that could be reused across multiple instances

**Example from librerama**:
- `GameManager` (autoload) — global lifecycle + settings
- `ArcadeManager` (autoload) — global arcade state
- Individual nanogames are regular scenes instantiated by the arcade machine

### Autoload Best Practices
- Always accessible by name in GDScript: `GameManager.is_locale_system_default()`
- For C#: use `static Instance` property set in `_Ready()`
- **Never** `queue_free()` or `free()` autoloading nodes — engine will crash

**Reference**: [Godot Docs — Singletons (Autoload)](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)

---

## 4. Resource Loading

### Preload vs Load
- **`preload(path)`**: resolves at compile time, front-loads loading, enables autocompletion
  - Use for static, known dependencies (scenes, configs, constants)
- **`load(path)`**: resolves at runtime, lazy loading
  - Use for dynamic/runtime-determined resources (mods, user content)
  - Or when you need to unload resources (preloaded can’t be garbage collected)

**Best Practice from librerama**:
```gdscript
# Correct: static dependency
const BuildingScn = preload("res://building.tscn")

# Correct: dynamic dependency
var office_scn = load("res://office.tscn")
```

---

## 5. Logic Preferences

### Node Initialization Order
1. **Set properties BEFORE `add_child()`** — setters may trigger expensive updates
2. **Exception**: `global_position` cannot be set before tree insertion
3. Use `call_deferred()` for operations during scene transitions (safe after current frame)

### Scene Transitions
```gdscript
func goto_scene(path):
    # Defer to next frame — current scene may still be executing code
    call_deferred("_deferred_goto_scene", path)

func _deferred_goto_scene(path):
    current_scene.free()
    var s = ResourceLoader.load(path)
    current_scene = s.instantiate()
    get_tree().root.add_child(current_scene)
```

---

## 6. Networking (Godot 4 High-Level API)

### RPC Annotations
```gdscript
@rpc("authority", "call_remote", "reliable", 0)
#                    ^       ^          ^
# mode: authority (server-only) | any_peer (clients)
# sync: call_remote (don't call locally) | call_local (call on all peers)
# transfer: reliable | unreliable | unreliable_ordered
# channel: 0, 1, 2 (independent streams)
```

### Security (Server-Authoritative)
- **Never trust client data**: validate ALL RPC arguments server-side
- Server is source of truth for: position, health, match state, objectives
- Client sends **input** (not state) → server validates → simulates → sends back
- Use `multiplayer.get_remote_sender_id()` to identify RPC caller

### MultiplayerSynchronizer
- Use for automatic property sync (`position`, `velocity`, `health`, `stunned`)
- `replication_interval = 1/30.0` (sync every 30 ticks, not every frame)
- `add_visibility_filter()` for distance/team-based culling
- **Cannot sync** `Object` or `RID` type properties

### Network Channels
- **Channel 0 (unreliable)**: movement packets (loss-tolerant, high frequency)
- **Channel 1 (reliable)**: state events (spawn, death, ability cast)
- **Channel 2 (reliable)**: chat messages
- Independence: channel 0 congestion doesn't block channel 2

**Reference**: [Godot Docs — High-Level Multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)

---

## 7. 2D Isometric (from godot-demo/isometric)

### TileMap Setup
```tscn
[node name="Floor" type="TileMap" parent="."]
y_sort_enabled = true
position = Vector2(-64, -32)
layer_0/y_sort_enabled = true
layer_0/y_sort_origin = 32  # Half of 64px tile height
```

### Isometric Movement
```gdscript
func _physics_process(delta):
    var motion = Vector2.ZERO
    motion.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    motion.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    motion.y /= 2  # Isometric foreshortening
    motion = motion.normalized() * SPEED
    set_velocity(motion)
    move_and_slide()
```

### Z-Ordering
1. `YSort` node under root for character sorting
2. Multiple `TileMap` layers (Floor = bottom, HighWalls = top)
3. `LightOccluder2D` for 2D lighting shadow casting
4. `Polygon2D` for custom shape rendering (projectiles, indicators)

---

## 8. Interpolation for High FPS (Godot 4)

### Built-in (project.godot)
```ini
[physics]
common/physics_ticks_per_second=60
common/physics_interpolation=true
```

### Custom Sprite Interpolation (for 120 FPS visual smoothing)
```gdscript
# On Sprite2D child of CharacterBody2D
var _prev_position: Vector2

func _ready():
    _prev_position = position
    set_physics_process_internal(true)

func _physics_process(delta):
    _prev_position = get_parent().position

func _process(delta):
    var factor = Engine.get_physics_frames_to_process() * Engine.get_physics_process_delta() - delta
    factor = clamp(factor, 0.0, 1.0)
    position = lerp(_prev_position, get_parent().position, factor)
```

### Key Rules
- Never move the `CharacterBody2D` in `_process()`
- Interpolation script is on the **visual child** (Sprite2D), not the physics parent
- Factor calculation accounts for the remainder between physics and render frames

---

## 9. Performance Optimization

### Mobile-Specific
- `renderer/rendering_mode = "mobile"` in project.godot
- Enable `compress/bptc_ldr` and `compress/lossy_quality` for texture compression
- Use `MultiMesh` for 100+ identical sprites (projectiles, particles)
- Canvas light culling via `light_cull_mask`

### Networking
- Use `distance_squared_to()` not `distance_to()` for range checks (no sqrt)
- Pool objects: projectiles, hit effects, UI widgets (pre-instantiate + reuse)
- Batch RPC calls: combine multiple property updates into single RPC
- Compress vector data: send `Vector2` not `Vector2` + separate `float` for speed

### Memory
- `preload()` for static dependencies (early load, no runtime overhead)
- `load()` for dynamic dependencies (can be unloaded by setting to `null`)
- Avoid `@export var` with `preload` initializer — scene instantiation overwrites it (wastes preload)
- Use `Resource` subclasses (`.tres`) for data-only objects (hero stats, skill configs)

---

## 10. Testing (GUT)

### Test Organization
- All tests in `src/tests/`, prefixed with `test_`
- Use `before_each()` / `after_each()` for setup/teardown
- Test names: `test_<system>_<behavior>()` (e.g., `test_health_component_damage_application`)

### Assertion Methods (GUT v9.7.1)
- `assert_eq(a, b, msg)` — equality
- `assert_true/false(value, msg)` — boolean
- `assert_not_null(obj, msg)` — non-null
- `assert_gt/lt(a, b, msg)` — comparison
- `assert_called(obj, method, args)` — signal/method spy (doubles)

### CLI Execution
```bash
godot --headless --path . --script addons/gut/gut_cli.gd -- -gtest --summary --exit
```

**Reference**: [GUT on GitHub](https://github.com/bitwes/Gut), [GUT Wiki](https://gut.readthedocs.io/)
