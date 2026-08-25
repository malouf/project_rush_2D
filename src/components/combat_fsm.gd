##============================================================================##
#  combat_fsm.gd — Node-based Finite State Machine for combat                    #
#  Pattern: same as MovementFSM but tracks casting/reloading state.              #
##============================================================================##

class_name CombatFSM
extends Node

signal state_changed(from: int, to: int)
signal cast_started(skill: BaseSkill)
signal cast_finished(skill: BaseSkill)
signal reloaded()

enum State {
	READY,
	CASTING,
	RELOADING,
	STUN,
}

@export var initial_state: State = State.READY

var current_state: State = State.READY
var current_skill: BaseSkill = null
var state_time: float = 0.0
var _entered_at_ms: int = 0
var _states: Dictionary = {}
var _cast_timer: SceneTreeTimer = null


func _ready() -> void:
	for child in get_children():
		if child is CombatState:
			_states[child.name] = child
			child.fsm = self
	transition_to(initial_state)


func _process(delta: float) -> void:
	state_time = (Time.get_ticks_msec() - _entered_at_ms) / 1000.0
	var state_node: CombatState = _get_state_node(current_state)
	if state_node:
		state_node.state_process(delta)


## ------------- Public API ------------- ##

func set_skill(skill: BaseSkill) -> void:
	current_skill = skill


func try_cast(target_pos: Vector2, target_hero: BaseHero = null) -> bool:
	if current_state != State.READY:
		return false
	if current_skill == null:
		return false
	cast_started.emit(current_skill)
	current_skill.on_cast_start(target_pos, target_hero)
	transition_to(State.CASTING)
	return true


func enter_stun() -> void:
	transition_to(State.STUN)


func exit_stun() -> void:
	if current_state == State.STUN:
		transition_to(State.READY)


## ------------- State machine ------------- ##

func transition_to(new_state: State) -> void:
	if new_state == current_state:
		return
	var previous: State = current_state
	var prev_node: CombatState = _get_state_node(previous)
	if prev_node:
		prev_node.state_exit()
	current_state = new_state
	_entered_at_ms = Time.get_ticks_msec()
	state_time = 0.0
	var new_node: CombatState = _get_state_node(new_state)
	if new_node:
		new_node.state_enter()
	state_changed.emit(previous, new_state)


func _get_state_node(state: State) -> CombatState:
	var key: String = ""
	match state:
		State.READY:
			key = "Ready"
		State.CASTING:
			key = "Casting"
		State.RELOADING:
			key = "Reloading"
		State.STUN:
			key = "Stun"
	if _states.has(key):
		return _states[key]
	for child in get_children():
		if child is CombatState and child.name.to_lower() == key.to_lower():
			return child
	return null


## Called by BaseSkill when the cast finishes (after cast_time).
func _on_cast_complete() -> void:
	cast_finished.emit(current_skill)
	if current_skill and current_skill.cooldown > 0.0:
		transition_to(State.RELOADING)
	else:
		transition_to(State.READY)


## Called by BaseSkill when the reload finishes (after cooldown).
func _on_reload_complete() -> void:
	reloaded.emit()
	transition_to(State.READY)
