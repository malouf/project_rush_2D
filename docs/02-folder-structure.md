# Folder Structure & Naming Conventions

## Directory Layout

```
project_rush_2d/
├── project.godot               # Engine config
├── .gitignore                  # .godot/ cache, *.import, logs
├── .gitattributes              # LF normalization + Git LFS for binary assets
├── README.md
├── docs/                       # Documentation (.gdignore to prevent import)
├── managers/                   # Autoload singletons (librerama pattern)
│   ├── game_manager.{tscn,gd}  # CanvasLayer: transitions + settings
│   ├── game_network.gd         # Network state (multiplayer_bomber pattern)
│   ├── event_bus.gd            # Global signal hub
│   ├── analytics.gd            # Analytics facade
│   └── ui_manager.gd           # Screen navigation
├── places/                     # Game location scenes (librerama pattern)
│   ├── main_menu/
│   ├── lobby/
│   ├── settings_menu/
├── prefabs/                    # Reusable scene templates (PlaneShooter pattern)
│   ├── hero.tscn, projectile.tscn, hit_effect.tscn, hit_marker.tscn
├── src/                        # Source code (organized by system)
│   ├── core/                   # Abstract bases: BaseHero, BaseSkill, DamagePayload
│   ├── components/            # Reusable: Health, HurtBox, HitBox, FSM
│   ├── combat/                # Weapons, lag compensation, smart casting
│   ├── network/               # Lobby, matchmaker, prediction, reconciliation
│   ├── ai/                    # Bot AI, behavior trees
│   ├── backend/               # Nakama, AdMob, IAP, Battle Pass
│   ├── accessibility/         # Colorblind, text scaling, HUD layout
│   ├── heroes/                # Hero configs, skills, bots
│   ├── game_modes/            # Control, Escort, Nano Grab modes
│   ├── ui/                    # Screens, widgets, themes
│   ├── maps/                  # Per-mode map scenes
│   └── tests/                 # GUT test scripts
├── assets/                     # Raw + imported resources
│   ├── sprites/{heroes,effects,ui,environment}/
│   ├── audio/{sfx,music,ui}/
│   ├── fonts/  tiles/  themes/
├── addons/                     # Third-party plugins (Godot convention)
│   ├── gut/        # v9.7.1 for Godot 4.7
│   ├── limboai/
│   ├── admob_plugin/
│   ├── godot_play_game_services/
│   └── godot_ios_plugins/
├── scenes/                     # Top-level scene files
│   ├── main.tscn               # Root: Main -> World + GUI
│   ├── world.tscn              # YSort container
│   └── hud.tscn                # HUD overlay
└── export/                     # Build artifacts (gitignored)
```

## Naming Conventions

| Element | Convention | Example | Source |
|---|---|---|---|
| Folders | `snake_case` | `game_modes/` | Godot docs |
| GDScript files | `snake_case` | `health_component.gd` | Godot docs |
| Node names | `PascalCase` | `HealthComponent` | Godot docs + librerama |
| Scenes (.tscn) | `snake_case` | `hero.tscn` | Godot docs |
| Resources (.tres) | `snake_case` | `hero_assault.tres` | Godot docs |
| Autoload singletons | `PascalCase` | `EventBus`, `GameManager` | librerama project.godot |
| Signals | `snake_case` | `health_changed` | librerama convention |
| Enums | `SCREAMING_SNAKE` | `STATE_IDLE` | librerama convention |

## .gitignore

```gitignore
# Godot
.import/
.godot/
*.godot.import
godot_*.log
export.cfg

# OS
.DS_Store
Thumbs.db

# IDEs
.vs/
.idea/
*.csproj
*.sln

# Editor
.editor/
```

## .gitattributes (Git LFS for binary assets)

```gitattributes
# Normalize EOL
* text=auto eol=lf

# Git LFS — images
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.webp filter=lfs diff=lfs merge=lfs -text
*.exr filter=lfs diff=lfs merge=lfs -text
*.hdr filter=lfs diff=lfs merge=lfs -text
*.dds filter=lfs diff=lfs merge=lfs -text

# Audio
*.wav filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text

# Fonts
*.ttf filter=lfs diff=lfs merge=lfs -text
*.otf filter=lfs diff=lfs merge=lfs -text
*.woff filter=lfs diff=lfs merge=lfs -text
*.woff2 filter=lfs diff=lfs merge=lfs -text

# Godot Resources
*.scn filter=lfs diff=lfs merge=lfs -text
*.tscn filter=lfs diff=lfs merge=lfs -text
*.tres filter=lfs diff=lfs merge=lfs -text
*.res filter=lfs diff=lfs merge=lfs -text
*.material filter=lfs diff=lfs merge=lfs -text
*.shader filter=lfs diff=lfs merge=lfs -text
*.mesh filter=lfs diff=lfs merge=lfs -text
*.anim filter=lfs diff=lfs merge=lfs -text
*.lmbake filter=lfs diff=lfs merge=lfs -text
```
