# Phase 8: Quality Control & Tests (GUT)

## Goal
Implement comprehensive GUT v9.7.1 test suites for all critical systems.
Run via headless CLI execution. HIGH priority tests gate all PRs.

## Adapted from
- **GUT GitHub** (bitwes/Gut v9.7.1 for Godot 4.7) — official test framework
- **librerama** project.godot — debug warning settings (`untyped_declaration=1`, `unsafe_cast=1`)

## GUT Installation & Setup

1. Download GUT 9.7.1 from: https://github.com/bitwes/Gut/releases/tag/v9.7.1
2. Extract `addons/gut/` into project's `addons/gut/`
3. Enable plugin via Project Settings → Plugins → GUT
4. Create `.gutconfig.json` at project root:

```json
{
  "directories": ["res://src/tests/"],
  "ignore_folders_on_glob_scan": true,
  "junit_xml_file": "user://gut_results.xml",
  "output_format": "console",
  "summary_on_success": true
}
```

## CLI Execution

```bash
# Run all tests (headless)
godot --headless --path . --script addons/gut/gut_cli.gd -- -gtest --summary --exit

# Run single test file
godot --headless --path . --script addons/gut/gut_cli.gd -- -gtest --test=res://src/tests/test_health_component.gd

# Run with coverage
godot --headless --path . --script addons/gut/gut_cli.gd -- -gtest --coverage --coverage-format=html

# Run with specific output
godot --headless --path . --script addons/gut/gut_cli.gd -- -gtest --output=pretty
```

## Test File Template (src/tests/_test_template.gd)

```gdscript
extends "res://addons/gut/gut_test_case.gd"

# Setup runs before each test method
func before_each():
    # Reset state
    pass

# Teardown runs after each test method
func after_each():
    # Clean up
    pass

func test_example_assertions():
    # Assert methods available
    assert_eq(1 + 1, 2, "Basic addition")
    assert_true(true, "Boolean true")
    assert_false(false, "Boolean false")
    assert_not_null(self, "Object exists")
    assert_gt(5, 3, "Greater than")
    assert_lt(1, 2, "Less than")
    # Custom assertions for game-specific types
    # assert_eq_vector(actual, expected, tolerance, message)

func test_will_fail_example():
    # This will show in output as a failure
    assert_eq(1, 2, "This should fail")
```

## Test Coverage Matrix

| System | Test File | Priority | Status | Test Cases |
|---|---|---|---|---|
| HealthComponent | `test_health_component.gd` | HIGH | Phase 4 | Damage, armor, overhealth, death, heal overflow |
| MovementFSM | `test_movement_fsm.gd` | HIGH | Phase 2 | Idle→Run→Stun transitions, input routing |
| Interpolation | `test_interpolation.gd` | MEDIUM | Phase 2 | Lerp correctness, no drift, factor clamping |
| ConfigManager | `test_config_encryption.gd` | HIGH | Phase 1 | Save/load round-trip, encrypted values, corruption recovery |
| DamagePayload | `test_damage_payload.gd` | HIGH | Phase 4 | Construction, field integrity, RPC serialization |
| HurtBox2D | `test_hurtbox_teams.gd` | MEDIUM | Phase 4 | Team filtering, invulnerability, damage type |
| HitBox2D | `test_hitbox_detection.gd` | MEDIUM | Phase 4 | Range detection, knockback, is_hitscan flag |
| Tap-to-Cast | `test_tap_to_cast.gd` | HIGH | Phase 5 | Nearest-target, LOS filtering, range limit |
| Drag-to-Aim | `test_drag_to_aim.gd` | MEDIUM | Phase 5 | Indicator spawn, direction, cancel behavior |
| Screen Shake | `test_screen_shake.gd` | LOW | Phase 5 | Bounds, duration, cleanup |
| Color-Blind Filter | `test_color_blind_filter.gd` | LOW | Phase 5 | Shader params per mode, strength scaling |
| Lag Compensation | `test_lag_compensation.gd` | HIGH | Phase 4 | Snapshot buffer, rewind, hit rejection |
| Client Prediction | `test_client_prediction.gd` | HIGH | Phase 3 | Input order, pending buffer, prediction error |
| Server Reconciliation | `test_reconciliation.gd` | HIGH | Phase 3 | Threshold, rewind+replay, state convergence |
| Bot Behavior Tree | `test_bot_bt.gd` | MEDIUM | Phase 6 | State transitions, role logic, difficulty modifiers |
| Bot Navigation | `test_bot_navigation.gd` | MEDIUM | Phase 6 | Pathfinding, obstacle avoidance, cover points |
| Matchmaking | `test_matchmaking.gd` | MEDIUM | Phase 7 | Ticket creation, query format, result parsing |
| Battle Pass | `test_battle_pass.gd` | MEDIUM | Phase 7 | Tier progression, reward claiming |

## CI/CD Integration (.github/workflows/tests.yml)

```yaml
name: GUT Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4  # For Git LFS
        with:
          node-version: '20'
      - name: Install Git LFS
        run: |
          sudo apt-get update
          sudo apt-get install -y git-lfs
          git lfs install
          git lfs pull
      - name: Run GUT Tests
        run: |
          godot --headless --path . --script addons/gut/gut_cli.gd \
            -- -gtest --summary --exit --output=pretty
```

## Performance Benchmarks (Integrated Tests)

| Test | Metric | Threshold | Method |
|---|---|---|---|
| `test_60fps_mobile.gd` | frame time < 16.67ms | 60 FPS minimum | Simulate 8 players, mid-tier GPU profile |
| `test_120fps_render.gd` | interpolation factor correctness | 120 FPS visual | Verify sprite lerp produces smooth motion |
| `test_network_bandwidth.gd` | < 10KB/s per client | Bandwidth efficiency | Measure ENet packet sizes over 30s |
| `test_reconciliation_latency.gd` | < 50px error | 150ms RTT simulation | CSP + reconciliation error margin |
| `test_lag_comp_500ms.gd` | No false positives | 500ms history | Verify old snapshots are rejected correctly |

## Code Quality Enforcement

- **Strict typing**: `@export`, `var`, and function params must be typed
- **No untyped declarations**: `gdscript/warnings/untyped_declaration=1` in project.godot
- **No unsafe casts**: `gdscript/warnings/unsafe_cast=1`
- **Line length**: 100 characters max (enforced via editor settings)
- **Test coverage gates**:
  - HIGH priority: 100% pass required for PR merge
  - MEDIUM priority: 100% pass required for PR merge
  - LOW priority: must not regress existing pass rate
  - Coverage targets: components 90%, combat 80%, network 70%
