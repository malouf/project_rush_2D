# Project Rush 2D

A mobile 2D isometric hero-shooter (4v4) built with Godot 4.7, targeting
"Blizzard Polish" standards: 60–120 FPS render, 60 Hz physics, server-authoritative
netcode with client-side prediction, and ethical freemium monetization.

## Quick Start

1. Open `project.godot` in Godot 4.7
2. Install GUT plugin from `addons/gut/` for testing
3. See `docs/` for full architecture and phase-by-phase implementation plan

## Key Technologies

- **Engine**: Godot 4.7 (GDScript, strict typing)
- **Networking**: ENet (server-authoritative), MultiplayerSynchronizer
- **Backend**: Nakama (auth, matchmaking, social)
- **AI**: LimboAI (behavior trees)
- **Testing**: GUT v9.7.1
- **Monetization**: Rewarded Ads (AdMob) + Battle Pass (IAP)

## Phase Roadmap

| Phase | Focus |
|---|---|
| 1 | Infrastructure, Menus, Telemetry |
| 2 | Movement & Interpolation |
| 3 | Networking & Prediction |
| 4 | Combat & Lag Compensation |
| 5 | Smart Casting & Game Feel |
| 6 | Tactical AI |
| 7 | Backend Integration |
| 8 | QA & Testing |
