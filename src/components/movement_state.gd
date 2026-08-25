##============================================================================##
#  movement_state.gd — Base class for a single movement FSM state node           #
##============================================================================##

class_name MovementState
extends Node

var fsm: MovementFSM

## Called once when entering this state.
func state_enter() -> void:
	pass

## Called every frame while in this state (with delta).
func state_process(delta: float) -> void:
	pass

## Called once when leaving this state.
func state_exit() -> void:
	pass
