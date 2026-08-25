##============================================================================##
#  HurtBox2D.gd — Damage receiver component                                    #
#  Adapted from: Document "Component HurtBox2D"                                #
##============================================================================##

class_name HurtBox2D
extends Area2D

signal hurt_received(payload: DamagePayload)

@export var defense_multiplier: float = 1.0:
	set(value):
		defense_multiplier = max(0.1, value)
@export var team_id: int = 0
var invulnerable: bool = false:
	set(value):
		invulnerable = value
		modulate = Color(1, 1, 1, 0.5) if value else Color(1, 1, 1, 1)

func _ready() -> void:
	connect("area_entered", _on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is HitBox2D and not invulnerable:
		var hitbox = area as HitBox2D
		if hitbox.team_id != team_id:
			var payload: DamagePayload = hitbox.create_payload(global_position)
			var damage: int = payload.amount
			# Apply defense multiplier
			if defense_multiplier < 1.0:
				damage = int(damage * defense_multiplier)
			payload.amount = damage

			hurt_received.emit(payload)

			# Forward to HealthComponent
			var health: HealthComponent = get_parent().get_node("HealthComponent") if get_parent().has_node("HealthComponent") else null
			if health:
				var actual_damage: int = health.take_damage(
					payload.amount, payload.damage_type, payload.is_critical)

			# Emit feedback via EventBus
			EventBus.player_damaged.emit(get_parent(), payload.amount, payload.is_critical)
