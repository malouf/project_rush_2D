##============================================================================##
#  idle_state.gd — Hero is stationary.  Plays idle anim, restores resources.    #
##============================================================================##

class_name IdleState
extends MovementState

@export var time_in_state: float = 0.0


func state_enter() -> void:
	time_in_state = 0.0


func state_process(delta: float) -> void:
	time_in_state += delta
