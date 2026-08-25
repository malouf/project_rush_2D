##============================================================================##
#  combat_fsm.gd — Node-based Finite State Machine for combat                  #
#  Adapted from: Document "Machines d'Etats Finis" (combat FSM)                #
##============================================================================##

class_name CombatFSM
extends Node

enum State {
	READY,
	CASTING,
	RELOADING,
	STUNNED,
}

var current_state: State = State.READY
var current_skill: BaseSkill = null

func set_skill(skill: BaseSkill) -> void:
	current_skill = skill

func try_cast(target_pos: Vector2, target_hero: BaseHero = null) -> bool:
	if current_state != State.READY:
		return false
	if current_skill == null:
		return false

	transition_to(State.CASTING)
	return true

func transition_to(state: State) -> void:
	if state == current_state:
		return
	match state:
		State.READY:
			enter_ready()
		State.CASTING:
			enter_casting()
		State.RELOADING:
			enter_reloading()
		State.STUNNED:
			enter_stunned_combat()
	current_state = state

func enter_ready() -> void:
	if current_skill and current_skill._is_charging:
		current_skill._is_charging = false

func enter_casting() -> void:
	if current_skill and current_skill.cast_time > 0:
		_transition_after(current_skill.cast_time, State.READY)

func enter_reloading() -> void:
	if current_skill:
		_transition_after(current_skill.cooldown, State.READY)

func enter_stunned_combat() -> void:
	pass

func _transition_after(time: float, target_state: State) -> void:
	await get_tree().create_timer(time).timeout
	transition_to(target_state)
