##============================================================================##
#  base_hero.gd — Abstract base class for all heroes                            #
#  Adapted from: librerama player.gd (CanvasLayer root + autoload settings),    #
#                multiplayer_bomber player.gd (network authority),              #
#                isometric demo goblin.gd (isometric movement transform)        #
##============================================================================##

class_name BaseHero
extends CharacterBody2D

## ---------------- Signals ---------------- ##
signal hero_died(hero: BaseHero)
signal health_changed(old_hp: int, new_hp: int, overhealth: int)
signal took_damage(amount: int, is_critical: bool)

## ---------------- Constants ---------------- ##
const SPEED: float = 160.0
const MAX_SPEED: float = 220.0
const ACCELERATION: float = 12.0
const FRICTION: float = 14.0

## Isometric transform: top-down input -> isometric world.
## From the isometric demo (goblin.gd) which divides Y by 2 for foreshortening.
const ISO_Y_FORE_SHORTEN: float = 0.5

## ---------------- Exports ---------------- ##
@export var team_id: int = 0
@export var max_health: int = 200
@export var armor: int = 50

## Network authority (from multiplayer_bomber pattern)
var is_local_authority: bool = true:
	set(value):
		is_local_authority = value
		# Disable input processing on non-authoritative instances.
		set_process_input(value)
		set_physics_process(value)

## ---------------- Children ---------------- ##
@onready var movement_fsm: MovementFSM = $MovementFSM
@onready var combat_fsm: CombatFSM = $CombatFSM
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: HurtBox2D = $HurtBox2D
@onready var hitbox: HitBox2D = $HitBox2D
@onready var visual: Node2D = $Visual
@onready var interpolation: Interpolation = $Visual/Interpolation

## ---------------- State ---------------- ##
var velocity_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN
var is_dead: bool = false

## ============== Lifecycle ============== ##

func _ready() -> void:
	hurtbox.team_id = team_id
	hitbox.team_id = team_id
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	hurtbox.hurt_received.connect(_on_hurt_received)


## ============== Movement ============== ##

func _physics_process(delta: float) -> void:
	if not is_local_authority or is_dead:
		return

	if movement_fsm and movement_fsm.is_stunned():
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		move_and_slide()
		return

	# Read top-down input from the player.
	var input_dir: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	)

	# Convert to isometric direction.  From the isometric demo, Y is foreshortened.
	var iso_dir: Vector2 = Vector2(input_dir.x, input_dir.y * ISO_Y_FORE_SHORTEN)
	if iso_dir.length() > 1.0:
		iso_dir = iso_dir.normalized()

	# Update FSM.
	if movement_fsm:
		movement_fsm.set_input(iso_dir)

	# Apply acceleration/friction.
	if iso_dir.length() > 0.01:
		var target_velocity: Vector2 = iso_dir * SPEED
		velocity = velocity.move_toward(target_velocity, ACCELERATION * SPEED * delta)
		velocity_direction = iso_dir
		facing_direction = iso_dir
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		velocity_direction = Vector2.ZERO

	# Clamp top speed (safety against physics spikes).
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED

	move_and_slide()


## ============== Damage ============== ##

func _on_hurt_received(payload: DamagePayload) -> void:
	took_damage.emit(payload.amount, payload.is_critical)
	if not is_local_authority:
		# Only authority applies damage; on remotes we just animate.
		return
	var actual: int = health_component.take_damage(
		payload.amount, payload.damage_type, payload.is_critical
	)


func _on_health_changed(old_hp: int, new_hp: int, overhealth: int) -> void:
	health_changed.emit(old_hp, new_hp, overhealth)


func _on_died(_hero: Node) -> void:
	is_dead = true
	hero_died.emit(self)
	# Disable collision and movement.
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	modulate = Color(0.5, 0.5, 0.5, 0.7)
