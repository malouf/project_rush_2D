##============================================================================##
#  BaseSkill.gd — Abstract base class for all skills                            #
#  Adapted from: Document "BaseSkill" spec                                    #
##============================================================================##

class_name BaseSkill
extends Resource

enum TargetingMode {
	TAP_TO_CAST,
	DRAG_TO_AIM,
	TARGET_LOCK,
}

## Core properties
@export var name: String = "Unnamed"
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

## Runtime state
var _current_cooldown: float = 0.0
var _is_charging: bool = false

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
	return true

func execute(caster: BaseHero, target_position: Vector2,
		target_hero: BaseHero = null, is_local: bool = true) -> bool:
	if not can_cast(caster):
		return false

	_is_charging = true
	if cast_time > 0:
		await caster.get_tree().create_timer(cast_time).timeout
	_is_charging = false

	_current_cooldown = cooldown

	if is_local:
		_play_cast_fx(caster, target_position)

	return true

func _play_cast_fx(caster: BaseHero, target_position: Vector2) -> void:
	EventBus.screen_shake_requested.emit(
		Vector2(3, 3), 0.15, 0)
