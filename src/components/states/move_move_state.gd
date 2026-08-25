##============================================================================##
#  move_state.gd — Hero is moving.  Updates facing direction.                   #
##============================================================================##

class_name MoveState
extends MovementState

var facing_changed: bool = false

## Optional reference back to the hero so we can update facing.  Set by the hero
## at runtime via `state.owner_hero = self`.
var owner_hero: BaseHero = null


func state_enter() -> void:
	facing_changed = false


func state_process(_delta: float) -> void:
	if owner_hero == null:
		return
	if fsm.movement_input.length() > 0.01:
		owner_hero.facing_direction = fsm.movement_input
