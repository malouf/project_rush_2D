# Phase 1: Infrastructure, Menus, Telemetry

## Goal
Establish project scaffolding: autoload singletons, settings system, menu navigation,
native auth stubs, AdMob interface, and analytics facade. No gameplay logic.

## Adapted from
- **librerama** `game_manager.gd` — ConfigFile settings, fade transitions, async loading
- **librerama** `settings_modal.gd` — sectioned settings UI pattern
- **multiplayer_bomber** `gamestate.gd` — network connection signal handlers

## Implementation Tasks

### 1. GameManager Autoload (managers/game_manager.gd)
- `extends CanvasLayer` (persistent overlay, survives scene transitions)
- **Settings via ConfigFile** (from librerama):
  - Sections: `[general]`, `[audio]`, `[controls]`, `[accessibility]`
  - Save path: `user://settings.cfg`
  - `save_settings()` / `load_settings()` — type-check all values (like librerama)
  - Sensitive tokens: `FileAccess.save_encrypted_pass()` for session data
- **Scene transitions** (from librerama):
  - `fade_in()` / `fade_out()` using `create_tween().set_parallel()`
  - `switch_main_scene(path)` with `ResourceLoader.load_threaded_request()`
- **Audio bus management** (from librerama): master(0), music(1), sfx(2)
  - `linear_to_db()` / `db_to_linear()` for slider values
- Custom project setting: `ProjectSettings.set_setting("game_settings/...", value)`

### 2. EventBus Autoload (managers/event_bus.gd)
- `extends Node`
- All signals (past-tense convention):
  - `settings_changed`, `game_started`, `game_ended`
  - `player_damaged`, `player_died`, `player_respawned`
  - `ability_used`, `ability_cooldown_updated`
  - `screen_shake_requested`, `hit_stop_requested`
  - `nano_collected`, `objective_captured`, `match_starting`, `match_ended`
  - `ui_screen_requested(screen_name, data)`

### 3. GameNetwork Autoload (managers/game_network.gd)
- `extends Node` — manages ENet connection state
- **Adapted from multiplayer_bomber/gamestate.gd**:
  - `DEFAULT_PORT = 10567`, `MAX_PEERS = 8`
  - `peer_connected(id)` → `register_player.rpc_id(id, ...)`
  - `peer_disconnected(id)` → erase player, check game state
  - `@rpc("any_peer")` `register_player(name)` → `players[id] = info`
  - `@rpc("call_local")` `load_world(path)` → load match scene
  - `players_loaded` counter → `start_game()` when all 8 ready
- Stub: no actual player spawning yet (deferred to Phase 3)

### 4. SSO & AdMob Stubs (src/backend/)
- `gpgs_interface.gd`: `authenticate()` → emits `social_auth_complete(token)` or `auth_failed`
- `gamecenter_interface.gd`: same interface pattern
- `ad_manager.gd`: `show_rewarded()`, `is_rewarded_ready()`, `request_consent()` (UMP/GDPR)
- `analytics.gd`: `track_event(name, params)` — local buffer, flush every 10 events

### 5. Menu Scenes (places/)
- `places/main_menu/main_menu.tscn` → connects to GameManager for scene switching
- `places/settings_menu/settings_menu.tscn` → binds to ConfigFile sections
  - Tabs: General, Audio, Controls, Accessibility (from librerama pattern)

## project.godot Settings to Apply

```ini
[autoload]
GameManager="res://managers/game_manager.gd"
GameNetwork="res://managers/game_network.gd"
EventBus="res://managers/event_bus.gd"
Analytics="res://managers/analytics.gd"

[debug]
gdscript/warnings/untyped_declaration=1
gdscript/warnings/unsafe_cast=1

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
window/stretch/aspect="keep_height"

[rendering]
renderer/rendering_method="mobile"
renderer/rendering_method.mobile="gl_compatibility"
rendering/quality/2d/use_pixel_snap=false

[input]
move_up/deadzone=0.2
move_down/deadzone=0.2
move_left/deadzone=0.2
move_right/deadzone=0.2
tap_to_cast/deadzone=0.1
drag_to_aim/deadzone=0.1
ui_accept/deadzone=0.5
ui_cancel/deadzone=0.5
```

## GUT Tests for Phase 1
- `test_config_serialization.gd`: verify save/load round-trip, encrypted sensitive data
- `test_event_bus.gd`: verify all signals fire correctly, no missed connections
- `test_network_autoload.gd`: verify signal handlers connected, port constants valid
