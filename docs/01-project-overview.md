# Project Rush 2D — Project Overview

## Code Name
**Project Rush 2D** — Mobile 2D isometric hero-shooter (4v4) targeting "Blizzard Polish"
standards: 60–120 FPS render, 60 Hz physics, server-authoritative netcode with
client-side prediction, and ethical freemium monetization.

## Vision
Transpose the competitive hero-shooter genre to mobile via Godot 4.7, with a
3-minute match loop, three game modes (Control, Escort, Nano Grab), and ethical
freemium monetization (Battle Pass + Rewarded Ads only, zero pay-to-win).

## Architecture Summary (adapted from librerama + multiplayer_bomber)

### Autoload Singletons (in `managers/`, per librerama pattern)

| Name | Base Class | Responsibility | Pattern Source |
|---|---|---|---|
| `GameManager` | `CanvasLayer` | Scene transitions, settings (ConfigFile), async loading | librerama `game_manager.gd` |
| `GameNetwork` | `Node` | ENet connection, player lobby, authority management | multiplayer_bomber `gamestate.gd` |
| `EventBus` | `Node` | Global signal dispatch for decoupled UI/combat | Document: "Call Down, Signal Up & Event Bus" |
| `Analytics` | `Node` | GameAnalytics/Firebase facade, batch telemetry | Document: "Télémétrie" |

### Key Patterns Applied
- **Godot 4 High-Level Multiplayer**: `ENetMultiplayerPeer`, `@rpc("authority", "reliable")`, `MultiplayerSynchronizer`
- **Client-Side Prediction**: Local input applied immediately; server validates + reconciles (multiplayer_bomber `player.gd` pattern where client runs physics, server sends `synced_position`)
- **Librerama-style Scene Management**: `ResourceLoader.load_threaded_request()` + fade transitions
- **Composition over Inheritance**: Heroes use HealthComponent, HurtBox2D, HitBox2D (document: "Architecture de Composition")
- **Node-Based FSM**: Separate movement FSM from combat FSM (document: "Machines d'États Finis")

## Spec Summary

| Parameter | Value |
|---|---|
| Engine | Godot 4.7 (GDScript, strict typing) |
| Perspective | 2D Isometric (2:1 ratio, 32px x 64px tiles) |
| Teams | 4v4 |
| Match Length | ~3 minutes (Bo1) |
| Physics | 60 Hz (`physics_ticks_per_second=60`, `interpolation=true`) |
| Render Target | 60–120 FPS (sprite interpolation via `_process`) |
| Network | Server-authoritative ENet (headless dedicated servers) |
| Backend | Nakama (matchmaking, MMR, social, chat, storage) |
| Monetization | Battle Pass (IAP) + Rewarded Video (AdMob UMP/GDPR) |
| Accessibility | Daltonism filters, text scaling, HUD repositioning |
| Testing | GUT v9.7.1 (HIGH priority tests gate all PRs) |

## Phase Roadmap

| Phase | Focus | Key Deliverables |
|---|---|---|
| 1 | Infrastructure, Menus, Telemetry | GameManager settings, EventBus, SSO/AdMob stubs |
| 2 | Movement & Interpolation | BaseHero, isometric controls, Node-based FSM, sprite lerp |
| 3 | Networking & Prediction | ENet server, GameNetwork lobby, CSP, reconciliation |
| 4 | Combat & Lag Comp | Health/HurtBox/HitBox, DamagePayload, 500ms position history |
| 5 | Smart Casting & Polish | BaseSkill resource, tap/drag/lock targeting, screen shake, hit-stop |
| 6 | Tactical AI | BotHero + LimboAI BT, NavigationAgent2D, role-based behavior |
| 7 | Backend Integration | Nakama auth, matchmaking, friends/guilds/chat, Battle Pass |
| 8 | QA & Testing | GUT suites for all critical systems + performance benchmarks |

## Development Approach
- **Phase-by-phase** (as requested): Complete each phase with simple placeholder graphics before moving on
- **Test-first**: GUT tests written alongside or before implementation code
- **Reference project adaptation**: Patterns from librerama, PlaneShooter, multiplayer_bomber applied throughout
