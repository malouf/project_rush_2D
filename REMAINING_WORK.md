# Remaining Work Summary - Project Rush 2D GUT Tests

## Test Status (as of last run)

| Test File | Status | Issues |
|-----------|--------|--------|
| test_health_component.gd | ✅ 8/8 PASS | None |
| test_base_hero.gd | ✅ 6/6 PASS | None |
| test_movement_fsm.gd | ⚠️ 8/9 PASS | 1 FAIL: `test_state_changed_signal` |
| test_interpolation.gd | 🔄 Needs re-run | Fixed syntax, not tested yet |
| test_network.gd | ✅ 5/5 PASS | Fixed autoload usage |
| test_combat.gd | ❌ Parse errors | Missing `_apply_cast_fx`, `_apply_hitscan`, `_spawn_projectile` in base_skill.gd (FIXED in code, needs re-test) |
| test_cast_input.gd | ❌ Parse errors | Missing `.tres` preloads, `AimIndicator` type, `get_world_2d()` on Node (PARTIALLY FIXED in code) |
| test_backend.gd | ❌ Parse errors | `IAPManager` parse error due to dual `class_name` in iap_manager.gd |
| test_ai.gd | ❌ Parse errors | `InRangeOfTargetCondition`, `FleeFromTargetAction` not resolved |

## Critical Fixes Needed

### 1. `src/backend/iap_manager.gd` - Dual class_name parse error
**Problem**: File has two `class_name` declarations:
- Line 6: `class_name IAPManager`
- Line 24: `class_name IAPProduct`
**Fix**: Move `IAPProduct` to separate file `src/backend/iap_product.gd` or remove `class_name` and use inner class syntax.

### 2. `src/ai/nodes/conditions.gd` - Inner class resolution
**Problem**: Multiple `class_name` declarations for ConditionNode, InRangeOfTargetCondition, etc. in one file.
**Fix**: Move each ConditionNode subclass to separate files or use inner class syntax without `class_name`.

### 3. `src/ai/nodes/actions.gd` - Inner class resolution  
**Problem**: Multiple `class_name` declarations for ActionNode, FleeFromTargetAction, etc.
**Fix**: Same as above - separate files or inner classes.

### 4. `src/tests/test_cast_input.gd` - Remaining issues after partial fix
- The fix for cast_input.gd removed preloads and AimIndicator type, but tests still fail due to missing resource files
- Need to either create dummy .tres files or fully mock in test

### 5. `src/tests/test_movement_fsm.gd` - 1 failing test
- `test_state_changed_signal` - investigate assertion logic

## Commands to Run Tests
```powershell
# Individual test
& "C:\Godot\Godot_v4.7-stable_win64_console.exe" -d --headless --path "C:\Godot\project_rush_2d" -s addons/gut/gut_cmdln.gd -gtest=res://src/tests/test_combat.gd -gexit -glog=0 --log-file "results_test_combat.gd.txt"

# All tests
for ($t in "test_health_component", "test_base_hero", "test_movement_fsm", "test_interpolation", "test_network", "test_combat", "test_cast_input", "test_backend", "test_ai") {
    & "C:\Godot\Godot_v4.7-stable_win64_console.exe" -d --headless --path "C:\Godot\project_rush_2d" -s addons/gut/gut_cmdln.gd -gtest="res://src/tests/$t.gd" -gexit -glog=0 --log-file "results_$t.gd.txt"
}
```

## Files Modified Since Last Commit
- src/core/base_skill.gd - Added missing functions
- src/skills/melee_slash.gd - Fixed _finish() cooldown logic
- src/ui/cast_input.gd - Removed preloads, fixed get_world_2d()
- src/tests/test_combat.gd - Fixed test logic, added owner setup
- src/tests/test_network.gd - Use autoload singleton directly
- src/tests/test_backend.gd - Use autoload for Analytics, instantiate others
- .godot/global_script_class_cache.cfg - Added GUT classes + BehaviorTreeNode

## Next Steps Priority
1. Fix iap_manager.gd (split IAPProduct to separate file)
2. Fix conditions.gd and actions.gd (split inner classes)
3. Re-run combat, cast_input, backend, ai tests
4. Fix movement_fsm test
5. Push all changes