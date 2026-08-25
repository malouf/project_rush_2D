##============================================================================##
#  BaseHero.gd — Abstract base class for all heroes                            #
#  Adapted from: isometric demo goblin.gd + multiplayer_bomber player.gd       #
##============================================================================##

class_name BaseHero
extends CharacterBody2D

## Movement constants (from isometric demo MOTION_SPEED)
const SPEED: float = 160.0
const MAX_SPEED: float = 220.0
const ACCELERATION: float = 10.0
const FRICTION: float = 8.0

## Hero stats (set via HeroData resource)
@export var hero_data: Resource  # HeroData resource
@export var team_id: int = 0

## Network authority
var is_local_authority: bool = true:
	set(value):
		is_local_authority = value

## FSM references
@onready var movement_fsm: MovementFSM = $MovementFSM
@onready var combat_fsm: CombatFSM = $CombatFSM

## Components
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: HurtBox2D = $HurtBox2D
@onready var hitbox: HitBox2D = $HitBox2D

## State
var velocity_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	hurtbox.team_id = team_id
	hitbox.team_id = team_id

func _physics_process(delta: float) -> void:
	if not is_local_authority or movement_fsm.current_state == MovementFSM.State.STUN:
		return

	# Isometric input (from goblin.gd pattern)
	var motion = Vector2.ZERO
	motion.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	motion.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	motion.y /= 2  # Isometric foreshortening
	motion = motion.normalized() * SPEED

	if motion.length() > 0.01:
		velocity = motion
		movement_fsm.set_input(motion)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		movement_fsm.set_input(Vector2.ZERO)

	move_and_slide()

func _process(delta: float) -> void:
	if velocity_direction.length() > 0.01:
		facing_direction = velocity_direction
