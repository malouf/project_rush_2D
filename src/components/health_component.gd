##============================================================================##
#  HealthComponent.gd — Manages health, armor, overhealth                      #
#  Adapted from: Document "Component Health" + librerama audio bus pattern       #
##============================================================================##

class_name HealthComponent
extends Node

signal health_changed(old_value: int, new_value: int, overhealth: int)
signal died(hero: Node)
signal shield_broken()
signal overhealth_expired()

## Configuration (set via HeroData or inspector)
@export var max_health: int = 200:
	set(value):
		max_health = max(1, value)
@export var armor: int = 50
@export var max_overhealth: int = 100

## Runtime state
var current_health: int = 200
var current_overhealth: int = 0
var is_alive: bool = true

## Overhealth decay
@export var overhealth_decay_per_sec: float = 15.0
var _decay_timer: Timer

func _ready() -> void:
	if max_health > 0 and current_health == 0:
		current_health = max_health
	if not _decay_timer:
		_decay_timer = Timer.new()
		_decay_timer.wait_time = 0.5
		_decay_timer.timeout.connect(_on_overhealth_decay)
		add_child(_decay_timer)
		_decay_timer.start()

func _on_overhealth_decay() -> void:
	if current_overhealth > 0:
		var old_overhealth = current_overhealth
		current_overhealth = max(0, current_overhealth - int(overhealth_decay_per_sec * _decay_timer.wait_time))
		health_changed.emit(current_health, current_health, current_overhealth)
		if old_overhealth > 0 and current_overhealth == 0:
			overhealth_expired.emit()

func take_damage(amount: int, damage_type: StringName = &"bullet",
		critical: bool = false) -> int:
	if not is_alive:
		return 0

	var damage: int = amount
	# Overhealth absorbs first
	if current_overhealth > 0:
		var absorbed: int = min(current_overhealth, damage)
		current_overhealth -= absorbed
		damage -= absorbed

	# Armor reduction (flat, unless critical bypasses armor)
	if not critical and armor > 0:
		damage = max(1, damage - armor)

	var old_health: int = current_health
	current_health = max(0, current_health - damage)
	health_changed.emit(old_health, current_health, current_overhealth)

	if current_health <= 0 and is_alive:
		is_alive = false
		died.emit(get_parent())

	return damage

func heal(amount: int) -> int:
	if not is_alive:
		return 0
	var old_health: int = current_health
	current_health = min(max_health, current_health + amount)
	if current_health != old_health:
		health_changed.emit(old_health, current_health, current_overhealth)
	return current_health - old_health

func apply_overhealth(amount: int, duration: float = 5.0) -> void:
	current_overhealth = min(max_overhealth, current_overhealth + amount)
	health_changed.emit(current_health, current_health, current_overhealth)

func apply_armor(amount: int) -> void:
	armor = max(0, armor + amount)

func apply_stun(duration: float) -> void:
	var parent_fsm: MovementFSM = get_parent().get_node("MovementFSM") if get_parent().has_node("MovementFSM") else null
	if parent_fsm:
		parent_fsm.enter_stun()

func is_dead() -> bool:
	return not is_alive

func get_health_percent() -> float:
	return float(current_health) / float(max_health) if max_health > 0 else 0.0
