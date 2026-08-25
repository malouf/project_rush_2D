##============================================================================##
#  HitBox2D.gd — Damage dealer component                                        #
#  Adapted from: Document "Component HitBox2D"                                 #
##============================================================================##

class_name HitBox2D
extends Area2D

@export var damage: int = 50
@export var damage_type: StringName = &"bullet"
@export var knockback: Vector2 = Vector2.ZERO
@export var is_hitscan: bool = true
@export var team_id: int = 0

func _ready() -> void:
	# HitBox should not collide with its own HurtBox
	collision_layer = 0
	collision_mask = 4  # HitBox layer
	set_physics_process(false)

func create_payload(hit_position: Vector2 = Vector2.ZERO) -> DamagePayload:
	var payload = DamagePayload.new()
	payload.shooter_id = team_id
	payload.shooter_team = team_id
	payload.amount = damage
	payload.damage_type = damage_type
	payload.knockback = knockback
	payload.is_critical = false
	payload.hit_position = hit_position if hit_position != Vector2.ZERO else global_position
	payload.timestamp = Time.get_ticks_msec()
	return payload

func _on_hit(target_hurtbox: HurtBox2D) -> void:
	if target_hurtbox is HurtBox2D and target_hurtbox.team_id != team_id:
		var payload: DamagePayload = create_payload(target_hurtbox.global_position)
		target_hurtbox.hurt_received.emit(payload)
