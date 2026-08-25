##============================================================================##
#  combat_state.gd — Base class for a single combat FSM state node                 #
##============================================================================##

class_name CombatState
extends Node

var fsm: CombatFSM

func state_enter() -> void:
	pass

func state_process(delta: float) -> void:
	pass

func state_exit() -> void:
	pass
