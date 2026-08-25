##============================================================================##
#  stun_state.gd — Hero is stunned.  Waits for stun to be cleared by combat.    #
##============================================================================##

class_name StunState
extends MovementState

@export var owner_hero: BaseHero = null


func state_exit() -> void:
	# When leaving stun, reset velocity direction so the hero doesn't drift.
	if owner_hero:
		owner_hero.velocity_direction = Vector2.ZERO
