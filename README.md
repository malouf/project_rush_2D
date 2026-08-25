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

All phases are complete! 

| Phase | Focus | Status |
|---|---|---|
| 1 | Infrastructure, Menus, Telemetry | ✅ Complete |
| 2 | Movement & Interpolation | ✅ Complete |
| 3 | Networking & Prediction | ✅ Complete |
| 4 | Combat & Lag Compensation | ✅ Complete |
| 5 | Smart Casting & Game Feel | ✅ Complete |
| 6 | Tactical AI | ✅ Complete |
| 7 | Backend Integration | ✅ Complete |
| 8 | QA & Testing | ✅ Complete |

## Documentation

See `docs/` for detailed documentation:
- [Project Overview](docs/01-project-overview.md)
- [Folder Structure](docs/02-folder-structure.md)
- [Phase 1: Infrastructure](docs/03-phase-1-infrastructure.md)
- [Phase 2: Movement & Interpolation](docs/04-phase-2-movement.md)
- [Phase 3: Networking & Prediction](docs/05-phase-3-networking.md)
- [Phase 4: Combat & Lag Compensation](docs/06-phase-4-combat.md)
- [Phase 5: Casting & Accessibility](docs/07-phase-5-casting-a11y.md)
- [Phase 6: AI & Bots](docs/08-phase-6-ai.md)
- [Phase 7: Backend Services](docs/09-phase-7-backend.md)
- [Phase 8: Testing & Polish](docs/10-phase-8-testing.md)
- [Godot Best Practices Reference](docs/godot-best-practices-reference.md)

## Testing

Run the test suite with:
```bash
./godot --headless -s addons/gut/gut.gd -- -S src/tests/ -G -G --include=src/tests/ --exclude=addons/gut/ --exit
```

Or use the provided GitHub Actions workflow (`.github/workflows/ci.yml`) for CI/CD.

## Export

Export templates are configured for:
- HTML5 (web)
- Android (APK/AAB)
- iOS (via Xcode)

See `export_presets.cfg` for details.

## License

MIT License - see [LICENSE](LICENSE) file.