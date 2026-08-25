# Phase 7: Integration Backend (Nakama Matchmaking)

## Goal
Connect client to Nakama for authentication, matchmaking (MMR-based), social features,
and integrate with dedicated server orchestration via Docker/Kubernetes.

## Adapted from
- **multiplayer_bomber** `gamestate.gd` — network connection lifecycle
- **librerama** `game_manager.gd` — async loading, settings persistence
- **Nakama SDK** documentation — matchmaker, storage, social APIs

## Nakama Authentication (src/backend/nakama_client.gd)

### Flow
1. **Startup**: Attempt native SSO auth (GPGS on Android, Game Center on iOS)
   - `GPGSInterface.authenticate()` → token → `Nakama.authenticate_custom(token)`
2. **Fallback**: Device ID → `Nakama.authenticate_custom(OS.get_unique_id())`
3. **Session storage**: Save token encrypted via `FileAccess.save_encrypted_pass()`
4. **Auto-refresh**: Nakama SDK handles `refresh_interval = 120s` automatically
5. **On app resume**: Check `session.is_expired()` → re-auth if needed

```gdscript
class_name NakamaClient extends Node

var _client: NakamaClient
var _session: NakamaSession
var _socket: NakamaSocket

func authenticate() -> void:
    var id = _get_native_token_or_device_id()
    _session = await _client.authenticate_custom(id).result
    # Persist encrypted session token
    ConfigManager.save_encrypted("social", "nakama_token", _session.token)

func _get_native_token_or_device_id() -> String:
    if OS.has_feature("android"):
        return await GPGSInterface.get_auth_token()
    elif OS.has_feature("ios"):
        return await GameCenterInterface.get_auth_token()
    else:
        return OS.get_unique_id()
```

## Matchmaking (src/network/matchmaker.gd)

### Flow
```
Client                    Nakama                   Orchestrator (K8s/Docker)
  │                          │                          │
  │ add_matchmaker(MMR)      │                          │
  ├─────────────────────────→│                          │
  │                          │                          │
  │                          │  Group 8 players by MMR  │
  │                          │─────────────────────────→│
  │      matchmaker_result   │                          │
  │◄─────────────────────────│                          │
  │                          │  spawn Godot headless pod │
  │                          │─────────────────────────→│
  │      IP:Port assigned     │   Pod ready + health OK  │
  │◄─────────────────────────│◄─────────────────────────│
  │                          │                          │
  │ join_game(ip, port)      │                          │
  ├───────────────────────────────────────────────────→│ (ENet)
  │  ENet connection established                        │
  │◄───────────────────────────────────────────────────│
```

### Client-Side Matchmaking
```gdscript
func start_matchmaking(mmr: int = 1000) -> void:
    var props = {"mmr": str(mmr)}
    var ticket = await _socket.add_matchmaker(
        min_count=8, max_count=8,
        query="mmr:1000-1200",  # Nakama matchmaker query syntax
        string_properties=props
    ).result
    _current_ticket = ticket
    assert(ticket.is_valid())
```

### Server-Side Orchestration
- **Webhook** (`/matchmaker_result`): Nakama calls K8s orchestrator when 8 players ready
- Orchestrator: spawns headless Godot pod via `kubectl run` or Agones `GameServer` CRD
- **Health check**: pod must respond `HTTP 200` on `/healthz` within 30s
- **IP assignment**: orchestrator calls `nakama.rpc("assign_ip", {pod_ip, pod_port})`
- Nakama broadcasts `matchmaker_result` to all 8 clients with ENet connection details

## Social Features (src/backend/social.gd)

| Feature | Nakama API | Data Structure |
|---|---|---|
| Friends | `FriendService.ListFriends` | `[{id, username, online, last_seen, avatar}]` |
| Friend Requests | `FriendService.AddFriends` | Send username/email → pending until accepted |
| Guilds | `GroupService` | `{id, name, tag, description, member_count, level, leader}` |
| Chat (Global) | `ChatService` | Channel: `mode:ROOM, room:"global"` |
| Chat (Match) | `ChatService` | Channel: `mode:ROOM, room:"match_<id>"` |
| Battle Pass | `StorageCollection` | `user_passport` in `storage` collection |
| Match History | `StorageCollection` | `user_matches` in `storage` collection |

### Match History Schema
```json
{
  "matches": [
    {
      "date": "2026-08-25T14:30:00Z",
      "hero": "Vanguard",
      "mode": "Control",
      "result": "win",
      "kills": 7,
      "deaths": 3,
      "assists": 5,
      "damage_dealt": 4200,
      "healing_done": 850
    }
  ]
}
```

## Battle Pass & Monetization (src/backend/battle_pass.gd + iap_manager.gd)

### Battle Pass Storage (Nakama StorageCollection)
```json
{
  "user_passport": {
    "version": 1,
    "tier": 23,
    "xp": 1450,
    "xp_to_next": 2000,
    "purchased": true,
    "premium_track": false,
    "rewards_claimed": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22],
    "season_id": "s3_invasion"
  }
}
```

### Purchase Flow
1. Client: `IAPManager.purchase("battle_pass_premium")`
2. Apple/Google: completes transaction, returns receipt
3. Client: `Nakama.rpc("validate_purchase", {platform, receipt, product_id})`
4. Server: validates receipt with Apple/Google API → if success → `storage.Write` with `premium_track=true`
5. Client: `EventBus.battle_pass_updated.emit(passport)` → UI refresh

### Rewarded Ads (only ad format — per document)
1. Client: `AdManager.show_rewarded()` → AdMob via Poing Studios plugin
2. User: watches 30s video (skippable after 5s)
3. On completion: `AdManager.rewarded_completed` → `Nakama.rpc("grant_reward", {type: "nano", amount: 25})`
4. Server: validates reward is claimable (daily limit, not already claimed) → response with success/failure

## GDPR/UMP Compliance
- On first launch in EU: show UMP consent form via AdMob plugin
- `ConfigManager.save("privacy", "consent_given", true/false)` to persist choice
- Analytics opt-out: `Analytics.enabled = false` if consent not given
- Data export: `Nakama.rpc("export_data", {})` returns all user data as JSON
- Account deletion: `Nakama.rpc("delete_account", {})` → anonymizes all stored data

## GUT Tests for Phase 7
- `test_nakama_auth.gd`: verify token exchange, session persistence, auto-refresh trigger
- `test_matchmaking.gd`: verify ticket creation, query string format, result parsing
- `test_battle_pass.gd`: verify tier progression, reward claiming, premium track logic
- `test_rewarded_ads.gd`: verify completion callback, daily limit enforcement
- `test_gdpr_consent.gd`: verify analytics disabled when consent denied
