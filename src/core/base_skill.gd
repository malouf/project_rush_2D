##============================================================================##
#  BaseSkill.gd — Abstract base class for all skills                            #
#  Pattern: Resource-based skill data + combat execution                       #
#  Adapted from: Document "BaseSkill" spec                                      #
##============================================================================##

class_name BaseSkill
extends Resource

## Targeting mode
enum TargetingMode {
	TAP_TO_CAST,   # Instant cast on tap
	DRAG_TO_AIM,   # Hold to charge, release to fire
	TARGET_LOCK,   # Auto-target nearest enemy
}

## Core properties
@export var skill_name: String = "Unnamed Skill"
@export var icon: Texture2D
@export var cooldown: float = 1.0
@export var mana_cost: int = 0
@export var range: float = 500.0
@export var cast_time: float = 0.0
@export var is_hitscan: bool = true
@export var targeting_mode: TargetingMode = TargetingMode.TAP_TO_CAST

## Combat data
@export var damage: int = 50
@export var damage_type: StringName = &"bullet"
@export var knockback: Vector2 = Vector2.ZERO
@export var projectile_scene: PackedScene
@export var is_heal: bool = false
@export var is_stun: bool = false

## Drag-to-aim properties
@export var drag_max_time: float = 2.0
@export var drag_max_range: float = 800.0

## Runtime state
var _current_cooldown: float = 0.0
var _is_charging: bool = false
var _charge_start_time: float = 0.0
var _charge_start_position: Vector2 = Vector2.ZERO
var _current_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	_is_charging = false

func update_cooldown(delta: float) -> void:
	if _current_cooldown > 0:
		_current_cooldown = max(0.0, _current_cooldown - delta)

func is_off_cooldown() -> bool:
	return _current_cooldown <= 0.0

func can_cast(caster: BaseHero) -> bool:
	if not is_off_cooldown():
		return false
	if caster == null:
		return false
	return true

## Execute the skill. Called by CombatFSM.
## Returns true if the skill was successfully cast.
func execute(caster: BaseHero, target_position: Vector2,
		target_hero: BaseHero = null) -> bool:
	if not can_cast(caster):
		return false

	_is_charging = true
	_current_cooldown = cooldown
	_charge_start_time = Time.get_ticks_msec()

	if targeting_mode == TargetingMode.DRAG_TO_AIM:
		# For drag-to-aim, we need the charge to persist until release
		# The actual firing happens in _on_skill_released
		_charge_start_position = caster.global_position
		_current_direction = (target_position - _charge_start_position).normalized()
		_apply_cast_fx(caster, target_position)
	else:
		# Normal execution - instant cast or projectile spawn
		if is_hitscan:
			_apply_hitscan(caster, target_position, target_hero)
		else:
			_spawn_projectile(caster, target_position)

	# Visual feedback
	_play_cast_fx(caster, target_position)

	# For DRAG_TO_AIM: don't reset _is_charging yet - it's set externally on release
	if targeting_mode != TargetingMode.DRAG_TO_AIM:
		_is_charging = false

	return true

## Called when the drag gesture ends (mouse released / finger lifted).
## Fires the skill with the accumulated aim direction.
func on_skill_released(caster: BaseHero, release_position: Vector2) -> void:
	if targeting_mode == TargetingMode.DRAG_TO_AIM and _is_charging:
		var charge_duration = (Time.get_ticks_msec() - _charge_start_time) / 1000.0
		var charge_factor = clamp(charge_duration / drag_max_time, 0.0, 1.0)
		
		# Calculate final direction from start position to release position
		var final_dir: Vector2 = (release_position - _charge_start_position).normalized()
		
		# Scale damage/knockback by charge factor if desired
		var final_damage: int = damage
		var final_knockback: Vector2 = knockback
		if is_stun:
			final_knockback = Vector2.ZERO
		
		# Fire the skill
		if is_hitscan:
			_apply_hitscan_with_dir(caster, final_dir, target_hero, final_damage, final_knockback)
		else:
			_spawn_projectile_with_dir(caster, final_dir, charge_factor)
		
		# Reset charge state
		_is_charging = false
	else:
		# Non-drag mode - just reset
		_is_charging = false

	_play_cast_fx(caster, caster.global_position if caster else Vector2.ZERO)


## Apply damage to target (hitscan) with explicit direction
func _apply_hitscan_with_dir(caster: BaseHero, direction: Vector2,
		target_hero: BaseHero, amount: int = -1, knockback: Vector2 = Vector2.ZERO) -> void:
	if target_hero:
		var dmg = amount != -1 and amount or damage
		var payload: DamagePayload = DamagePayload.new()
		payload.shooter_id = caster.team_id
		payload.shooter_team = caster.team_id
		payload.amount = dmg
		payload.damage_type = damage_type
		payload.knockback = knockback
		payload.is_critical = false
		payload.hit_position = target_hero.global_position
		payload.timestamp = Time.get_ticks_msec()
		target_hero.hurtbox.hurt_received.emit(payload)


## Spawn a projectile (non-hitscan) with explicit direction and charge factor
func _spawn_projectile_with_dir(caster: BaseHero, direction: Vector2,
		charge_factor: float) -> void:
	if projectile_scene == null:
		return
	var projectile = projectile_scene.instantiate()
	if projectile is Node2D:
		projectile.global_position = caster.global_position
		projectile.set("direction", direction)
		projectile.set("speed", 400.0 + charge_factor * 200.0)  # faster if charged
		projectile.set("damage", damage)
		projectile.set("damage_type", damage_type)
		projectile.set("shooter_team", caster.team_id)
		caster.get_parent().add_child(projectile)


## Visual feedback during cast
func _play_cast_fx(caster: BaseHero, target_position: Vector2) -> void:
	if caster:
		# Screen shake on cast
		EventBus.screen_shake_requested.emit(
			Vector2(3, 3), 0.15, 0)
		# Color flash
		if caster.visual:
			caster.visual.modulate = Color(1.5, 1.5, 1.5, 1.0)
			# Reset after 0.1s
			var reset_timer = Timer.new()
			reset_timer.wait_time = 0.1
			reset_timer.timeout.connect(func() -> void:
				if caster.visual:
					caster.visual.modulate = Color(1, 1, 1, 1)
			)
			caster.add_child(reset_timer)
			reset_timer.start()


func _physics_process(delta: float) -> void:
	# Handle drag charging - called from hero input processing
	if _is_charging and targeting_mode == TargetingMode.DRAG_TO_AIM:
		# Could update a UI indicator here
		pass