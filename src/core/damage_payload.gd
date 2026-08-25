##============================================================================##
#  DamagePayload.gd — Data structure for damage info                           #
#  Adapted from: Document "DamagePayload" spec                                #
##============================================================================##

class_name DamagePayload
extends Resource

## Shooter identity
var shooter_id: int = 0
var shooter_team: int = 0

## Damage info
var amount: int = 0
var damage_type: StringName = &"bullet"
var knockback: Vector2 = Vector2.ZERO
var is_critical: bool = false

## Hit info
var hit_position: Vector2 = Vector2.ZERO
var hit_normal: Vector2 = Vector2.UP

## Timing
var timestamp: int = 0  # Server tick or milliseconds

func _init(p_shooter_id: int = 0, p_amount: int = 0, p_type: StringName = &"bullet") -> void:
	shooter_id = p_shooter_id
	amount = p_amount
	damage_type = p_type
	timestamp = Time.get_ticks_msec()

func setup(p_shooter_id: int, p_shooter_team: int, p_amount: int, p_type: StringName,
		p_knockback: Vector2, p_critical: bool, p_position: Vector2) -> DamagePayload:
	shooter_id = p_shooter_id
	shooter_team = p_shooter_team
	amount = p_amount
	damage_type = p_type
	knockback = p_knockback
	is_critical = p_critical
	hit_position = p_position
	timestamp = Time.get_ticks_msec()
	return self
