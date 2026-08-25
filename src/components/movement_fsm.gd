##============================================================================##
#  movement_fsm.gd — Node-based Finite State Machine for movement               #
#  Adapted from: Document "Machines d'Etats Finis"                             #
##============================================================================##

class_name MovementFSM
extends Node

enum State {
	IDLING,
	MOVING,
	WEAKENING,
	STUNNED,
}

var current_state: State = State.IDLING
var movement_input: Vector2 = Vector2.ZERO

func set_input(input: Vector2) -> void:
	if current_state == State.STUNNED:
		return
	movement_input = input
	if input.length() > 0.01:
		if current_state != State.MOVING:
			transition_to(State.MOVING)
	else:
		if current_state != State.IDLING:
			transition_to(State.IDLING)

func transition_to(state: State) -> void:
	if state == current_state:
		return
	match state:
		State.IDLING:
			enter_idle()
		State.MOVING:
			enter_moving()
		State.STUNNED:
			enter_stunned()
	current_state = state

func enter_idle() -> void:
	pass

func enter_moving() -> void:
	pass

func enter_stunned() -> void:
	movement_input = Vector2.ZERO

func enter_stun() -> void:
	transition_to(State.STUNNED)

func is_stunned() -> bool:
	return current_state == State.STUNNED

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if get_child(0) is not Node:
		warnings.append("MovementFSM should have child state nodes.")
	return warnings
