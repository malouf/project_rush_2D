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

## Runtime state
var _current_cooldown: float = 0.0
var _is_charging: bool = false

## Cooldown management
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

	if is_hitscan:
		# Instant damage application
		_apply_hitscan(caster, target_position, target_hero)
	else:
		# Spawn projectile
		_spawn_projectile(caster, target_position)

	# Visual feedback
	_play_cast_fx(caster, target_position)

	_is_charging = false
	return true

## Apply damage to target (hitscan)
func _apply_hitscan(caster: BaseHero, target_position: Vector2,
		target_hero: BaseHero) -> void:
	if target_hero:
		# Direct damage to hero
		var payload: DamagePayload = DamagePayload.new()
		payload.shooter_id = caster.team_id
		payload.shooter_team = caster.team_id
		payload.amount = damage
		payload.damage_type = damage_type
		payload.knockback = knockback
		payload.is_critical = false
		payload.hit_position = target_hero.global_position
		payload.timestamp = Time.get_ticks_msec()
		target_hero.hurtbox.hurt_received.emit(payload)
	else:
		# Hitscan raycast for environment
		# (placeholder - Phase 4 doesn't need env damage)
		pass

## Spawn a projectile (non-hitscan)
func _spawn_projectile(caster: BaseHero, target_position: Vector2) -> void:
	if projectile_scene == null:
		return
	var projectile = projectile_scene.instantiate()
	if projectile is Node2D:
		projectile.global_position = caster.global_position
		# Set up direction
		var dir: Vector2 = (target_position - caster.global_position).normalized()
		projectile.set("direction", dir)
		projectile.set("speed", 400.0)
		projectile.set("damage", damage)
		projectile.set("damage_type", damage_type)
		projectile.set("shooter_team", caster.team_id)
		caster.get_parent().add_child(projectile)

## Visual feedback
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