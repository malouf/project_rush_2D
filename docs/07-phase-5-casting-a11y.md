# Phase 5: Smart Casting & Game Feel

## Goal
Implement BaseSkill resource system, mobile touch controls (tap-to-cast, drag-to-aim,
target lock), and "Blizzard Polish" feedback systems (hit markers, screen shake, hit-stop).

## Adapted from
- **PlaneShooter** `GameUI.gd` — UI widget structure, health bar pattern
- **librerama** `settings_modal.gd` — complex UI with tabs, dynamic content
- **isometric demo** — `Polygon2D` usage for visual indicators
- **Godot docs** CanvasItemMaterial — for color-blind shaders

## BaseSkill Resource System (src/core/base_skill.gd)

```gdscript
class_name BaseSkill extends Resource

enum TargetingMode { TAP_TO_CAST, DRAG_TO_AIM, TARGET_LOCK }

@export var name: String
@export var icon: Texture2D
@export var cooldown: float = 1.0
@export var mana_cost: int = 0
@export var range: float = 500.0
@export var cast_time: float = 0.0
@export var is_hitscan: bool = true
@export var targeting_mode: TargetingMode = TargetingMode.TAP_TO_CAST
@export var damage_payload: DamagePayload

# Returns true if skill was successfully cast
func execute(caster: BaseHero, target_position: Vector2,
        target_hero: BaseHero = null, is_local: bool = true) -> bool:
    if is_local:
        # Client: immediate visual feedback (prediction)
        _play_cast_fx(caster)
    # Server: validates range, LoS, cooldown, mana
    return true
```

### Skill Inheritance
- Each hero's skills extend `BaseSkill` (e.g., `class_name VortexGrenade extends BaseSkill`)
- Override `execute()` with skill-specific logic
- Skills registered as `.tres` resource files in `src/heroes/skills/`
- Loaded via `preload("res://src/heroes/skills/%s.tres" % skill_name)` (static path)

## Mobile Touch Controls (src/combat/smart_casting.gd)

### Tap-to-Cast (Auto-Targeting)
1. Player taps screen at `world_position`
2. Get all heroes in `range` using `distance_squared_to()` (performance: no sqrt)
3. Raycast from caster to each candidate (verify no wall occlusion)
4. Select nearest unobstructed valid target
5. Emit `EventBus.ability_used.emit(caster, skill, target)` → trigger cast

```gdscript
func _find_nearest_valid_target(caster: BaseHero, center: Vector2, range: float) -> BaseHero:
    var candidates = get_tree().get_nodes_in_group("heroes")
    var best: BaseHero = null
    var best_dist_sq = range * range
    for candidate in candidates:
        if candidate.team_id == caster.team_id:
            continue
        var dist_sq = center.distance_squared_to(candidate.global_position)
        if dist_sq > best_dist_sq:
            continue
        # Raycast for line-of-sight
        var space = get_world_2d().direct_space_state
        var query = PhysicsRayQueryParameters2D.create(caster.global_position, candidate.global_position)
        var result = space.intersect_ray(query)
        if result and result.collider == candidate:
            best = candidate
            best_dist_sq = dist_sq
    return best
```

### Drag-to-Aim
- On touch hold (0.1s threshold): spawn `Polygon2D` aim indicator
- Polygon: arrow shape (4 points) pointing in aim direction
- `move_and_slide()` on hero remains active — player can strafe while aiming
- On release: execute in aim direction → `EventBus.ability_used.emit(caster, skill, null, aim_direction)`
- Cancel: drag back toward hero origin within 100px radius → hide indicator

```gdscript
func _spawn_aim_indicator(start: Vector2, direction: Vector2):
    var indicator: Polygon2D = preload("res://prefabs/aim_indicator.tscn").instantiate()
    indicator.polygon = PoolVector2Array([Vector2(0, 0), Vector2(40, -20), Vector2(60, 0), Vector2(40, 20)])
    indicator.position = start
    indicator.rotation = direction.angle()
    get_tree().get_root().add_child(indicator)
```

### Target Lock
- Long-press (0.3s) on enemy → `EventBus.target_locked.emit(enemy)`
- Lock icon (reticle texture) appears above target
- Tap-to-cast abilities auto-target locked enemy with priority override
- Escape: target behind wall → lock breaks (periodic raycast check, 0.5s interval)

## Game Feel Systems

### Hit Markers (src/components/hit_marker.gd)
- Pool of 8 `Sprite2D` markers (pre-instantiated, reuse pattern from PlaneShooter)
- Textures: red diamond, yellow star, blue shield-break (all placeholder PNGs)
- Animation: scale tween (0.7 → 1.2 → 0.5) + fade (1.0 → 0.0) in 0.15s
- Duration: 0.15s total (matches document spec)

### Screen Shake (src/components/screen_shake.gd)
```gdscript
extends Node

var _intensity: Vector2 = Vector2.ZERO
var _duration: float = 0.0
var _elapsed: float = 0.0
var _is_shaking: bool = false
@onready var _camera: Camera2D = get_viewport().get_camera_2d()

func _process(delta: float) -> void:
    if not _is_shaking:
        return
    var offset = Vector2(
        randf_range(-_intensity.x, _intensity.x),
        randf_range(-_intensity.y, _intensity.y))
    _camera.offset = offset
    _elapsed += delta
    if _elapsed >= _duration:
        _is_shaking = false
        _camera.offset = Vector2.ZERO

func shake(intensity: Vector2, duration: float) -> void:
    _intensity = intensity * Settings.accessibility.shake_scale
    _duration = duration
    _is_shaking = true
    _elapsed = 0.0

# Connected via EventBus
func _ready():
    EventBus.screen_shake_requested.connect(shake)
```

### Hit-Stop (src/components/hit_stop.gd)
```gdscript
func trigger(duration_ms: float) -> void:
    if not Settings.accessibility.hit_stop_enabled:
        return
    # Cannot nest hit-stop
    if get_tree().paused:
        return
    get_tree().paused = true
    await get_tree().create_timer(duration_ms / 1000.0).timeout
    get_tree().paused = false

# Connected via EventBus
func _ready():
    EventBus.hit_stop_requested.connect(trigger)
```
- Duration: 3ms for normal hits, 8ms for critical melee
- Must NOT interrupt GameManager fade transitions (check `_switching_scene` flag)

## Accessibility (A11y)

### Color-Blind Filters (src/accessibility/color_blind_filter.gd)
- Modes: Protanopia (red-weak), Deuteranopia (green-weak), Tritanopia (blue-weak), Monochromacy
- Fullscreen `ColorRect` with `CanvasItemMaterial` + color remap shader
- Affects: enemy outlines, ability zone indicators, health bar colors
- Settings: `Settings.Accessibility.ColorBlindMode` (string), `ColorBlindStrength` (0.0–1.0)

### Text Scaling
- `Settings.Accessibility.TextScale` multiplier (0.8–2.0)
- Applied via `ThemeDB.fallback_font` size override + `Control.scale` on UI root
- All `Label` nodes use `theme_type_variation` for uniform propagation
- Follows librerama's pattern of reading from ConfigFile on load

### HUD Layout Customization
- Each widget (`HealthBar`, `AbilityCooldown`, `NanoCounter`) is a `Control` node
- Anchor presets: Top-Left, Top-Right, Bottom-Left, Bottom-Right, Center
- Opacity slider: 0.0–1.0 per widget
- Scale slider: 0.5–2.0 per widget
- Drag-to-reposition in settings menu (touch-and-hold)
- Position persisted in `user://hud_layout.cfg`

## GUT Tests for Phase 5
- `test_base_skill.gd`: verify execute() returns payload, cooldown tracking
- `test_tap_to_cast.gd`: verify nearest-target selection, wall occlusion rejection
- `test_drag_to_aim.gd`: verify Polygon2D indicator follows drag, movement unblocked
- `test_hit_marker.gd`: verify activation, pool reuse, correct color by damage type
- `test_screen_shake.gd`: verify camera offset within intensity bounds, cleanup after duration
- `test_color_blind_filter.gd`: verify shader parameter updates per mode selection
