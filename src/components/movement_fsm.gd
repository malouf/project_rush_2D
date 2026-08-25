##============================================================================##
#  movement_fsm.gd — Node-based Finite State Machine for movement               #
#  Pattern: simple state owner that delegates to child State nodes               #
#  Adapted from: Document "Machines d'Etats Finis" (librerama)                   #
##============================================================================##

class_name MovementFSM
extends Node

## Emitted when the state changes.
signal state_changed(from: int, to: int)

## States.  Keep this in sync with combat_fsm.gd's STUNNED name.
enum State {
	IDLE,
	MOVE,
	STUN,
}

@export var initial_state: State = State.IDLE

var current_state: State = State.IDLE
var movement_input: Vector2 = Vector2.ZERO
var state_time: float = 0.0

## Cached state nodes (one per state), discovered by name.
var _states: Dictionary = {}

## Time the current state was entered (ms).
var _entered_at_ms: int = 0


func _ready() -> void:
	# Discover child state nodes by name.
	for child in get_children():
		if child is MovementState:
			_states[child.name] = child
			child.fsm = self
	transition_to(initial_state)


func _process(delta: float) -> void:
	state_time = (Time.get_ticks_msec() - _entered_at_ms) / 1000.0
	var state_node: MovementState = _get_state_node(current_state)
	if state_node:
		state_node.state_process(delta)


## Public API: feed input vector (already in isometric space).
func set_input(input: Vector2) -> void:
	if current_state == State.STUN:
		# Stunned heroes ignore input.
		movement_input = Vector2.ZERO
		return
	movement_input = input
	if input.length() > 0.01 and current_state != State.MOVE:
		transition_to(State.MOVE)
	elif input.length() <= 0.01 and current_state == State.MOVE:
		transition_to(State.IDLE)


## Stun entry point (called by HealthComponent or combat).
func enter_stun() -> void:
	transition_to(State.STUN)


## Exit stun (called by stun timer or external event).
func exit_stun() -> void:
	if current_state == State.STUN:
		transition_to(State.IDLE)


func is_stunned() -> bool:
	return current_state == State.STUN


func is_moving() -> bool:
	return current_state == State.MOVE


func transition_to(new_state: State) -> void:
	if new_state == current_state:
		return
	var previous: State = current_state
	# Exit current.
	var prev_node: MovementState = _get_state_node(previous)
	if prev_node:
		prev_node.state_exit()
	current_state = new_state
	_entered_at_ms = Time.get_ticks_msec()
	state_time = 0.0
	# Enter new.
	var new_node: MovementState = _get_state_node(new_state)
	if new_node:
		new_node.state_enter()
	state_changed.emit(previous, new_state)


func _get_state_node(state: State) -> MovementState:
	# Map enum to child node name.
	var key: String = ""
	match state:
		State.IDLE:
			key = "Idle"
		State.MOVE:
			key = "Move"
		State.STUN:
			key = "Stun"
	if _states.has(key):
		return _states[key]
	# Fallback: search by name (case-insensitive on Godot 4).
	for child in get_children():
		if child is MovementState and child.name.to_lower() == key.to_lower():
			return child
	return null
