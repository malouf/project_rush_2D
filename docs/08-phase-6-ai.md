# Phase 6: Intelligence Artificielle Tactique (LimboAI)

## Goal
Create `BotHero` (extends `BaseHero`) with LimboAI behavior trees, NavigationAgent2D
pathfinding, and role-based tactical decision making for 4v4 matches.

## Adapted from
- **isometric demo** `goblin.gd` — `CharacterBody2D` movement, `move_and_slide()`
- **godot-demo** `navigation/` — `NavigationAgent2D` usage pattern
- **LimboAI plugin** documentation — behavior tree composition

## BotHero (src/heroes/bots/bot_hero.gd)

```gdscript
class_name BotHero extends BaseHero

@export var bot_difficulty: int = 1  # 1-5 (5 = near-human)
@export var tactical_role: String = "anchor"  # anchor, flanker, support, sniper
@export var bt_resource: LimboBehaviorTree

func _ready():
    bt_resource = load("res://src/ai/bt_definitions/bot_%s.tres" % tactical_role)
    var bt_player = LimboBTPlayer.new()
    bt_player.behavior_tree = bt_resource
    add_child(bt_player)
    bt_player.blackboard.set_value("self", self)
    bt_player.start(get_physics_process_delta())
```

## Behavior Tree Structure (src/ai/bt_definitions/)

```
Selector
├── Sequence
│   ├── Condition: health < 20%
│   └── Action: flee_to_cover
├── Sequence
│   ├── Condition: objective_active == true
│   └── Action: move_to_objective
├── Sequence
│   ├── Condition: enemy_in_range
│   └── Action: use_ability (priority: heal > CC > damage > auto-attack)
└── Action: idle_scan
    ├── Look for nearest visible enemy
    └── Set as blackboard target
```

### Blackboard Keys
- `self` — reference to BotHero node
- `target_hero` — current target NodePath
- `move_target` — Vector2 destination
- `enemies_nearby` — Array of nearby enemies
- `health_percent` — float (0.0–1.0)
- `current_mode` — enum (IDLE, ENGAGE, FLEE, OBJECTIVE)

## NavigationAgent2D (src/ai/bot_navigation.gd)

```gdscript
class_name BotNavigation extends Node

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var hero: BaseHero = get_parent()

func navigate_to(target: Vector2) -> void:
    agent.set_target_location(target)
    agent.path_requested_distance = 8.0  # Don't recalculate within 8px

func _physics_process(delta: float) -> void:
    if agent.is_path_reached() or not agent.is_navigation_finished():
        return
    var next_pos = agent.get_next_path_position()
    var direction = (next_pos - hero.global_position).normalized()
    hero.velocity = direction * hero.SPEED
```

### Pathfinding Settings
- `NavigationAgent2D.path_requested_distance = 8.0` (recalculate threshold)
- `agent.set_agent_radius(24)` — tight radius for aggressive positioning
- `agent.set_avoidance_enabled(true)` — avoid other agents + static obstacles
- Path recalculation: every 0.5s (timer, not every frame)
- Obstacle avoidance: `NavigationServer2D.agent_set_avoidance_layers()` for team-based filtering

## Role Behaviors

| Role | Behavior | Pathfinding | Key Settings |
|---|---|---|---|
| **Anchor** | Hold 300px from objective, engage at medium range | Static position ± 100px | Aggression=0.5, Retreat=0.2 |
| **Flanker** | Circle to backline, use mobility skills | Dynamic path every 3s | Aggression=0.8, Reposition=5.0s |
| **Support** | Stay behind anchors, heal nearest ally | Path to lowest-HP ally | HealThreshold=0.6, AssistRange=200 |
| **Sniper** | Maintain 400px+ distance, use cover | Reposition if enemy < 200px | SniperRange=500, MinDistance=200 |

## Difficulty Scaling

| Level | Input Delay | Aim Error | Skill Usage | Path Quality |
|---|---|---|---|---|
| 1 (Easy) | 1.0s | ±30px | Random (no priority) | Basic (straight-line) |
| 2 | 0.7s | ±20px | Basic priority | Smart (obstacle-aware) |
| 3 (Medium) | 0.4s | ±10px | Full priority queue | Optimal |
| 4 | 0.2s | ±5px | Predictive casts | Optimal + feinting |
| 5 (Hard) | 0.05s | ±2px | Perfect timing | Optimal + strafing |

### Difficulty modifiers applied via blackboard:
```gdscript
# In bot initialization
var difficulty_data: Dictionary = {
    1: {"input_delay": 1.0, "aim_error": 30.0, "skill_priority": false},
    3: {"input_delay": 0.4, "aim_error": 10.0, "skill_priority": true},
    5: {"input_delay": 0.05, "aim_error": 2.0, "skill_priority": true}
}
bt_player.blackboard.set_value("difficulty", difficulty_data)
```

## Cover System
- Each map has `cover_points` node group with pre-positioned `Marker2D` nodes
- Cover points tagged: `"high_cover"`, `"low_cover"`, `"flanking"`
- Bot evaluates cover quality: distance-to-target × safety-factor × angle-to-enemy
- `NavigationObstacle2D` on cover points prevents pathfinding through them

## GUT Tests for Phase 6
- `test_bot_bt.gd`: verify behavior tree transitions (LOW_HEALTH → FLEE, OBJECTIVE → ENGAGE)
- `test_bot_navigation.gd`: verify pathfinding around obstacles, agent avoidance, cover point selection
- `test_bot_target_selection.gd`: verify nearest-target selection within role constraints
- `test_bot_skill_usage.gd`: verify skill priority ordering, cooldown awareness, difficulty modifiers
- `test_difficulty_scaling.gd`: verify aim error range per level, input delay timing
