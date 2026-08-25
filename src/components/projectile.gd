##============================================================================##
#  projectile.gd — Non-hitscan projectile (Node2D + sprite + hitbox)             #
##============================================================================##

class_name Projectile
extends Node2D

@export var speed: float = 400.0
@export var damage: int = 50
@export var damage_type: StringName = &"bullet"
@export var knockback: Vector2 = Vector2.ZERO
@export var lifetime: float = 2.0
@export var shooter_team: int = 0
@export var direction: Vector2 = Vector2.RIGHT
@export var trail_color: Color = Color(1.0, 0.6, 0.2, 0.6)

@onready var _hitbox: HitBox2D = $HitBox2D
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _timer: Timer = $LifeTimer

var _is_dead: bool = false


func _ready() -> void:
	if _hitbox:
		_hitbox.team_id = shooter_team
		_hitbox.damage = damage
		_hitbox.damage_type = damage_type
		_hitbox.knockback = knockback.normalized() * speed * 0.05 if knockback == Vector2.ZERO else knockback
	if _timer:
		_timer.wait_time = lifetime
		_timer.timeout.connect(_on_lifetime_expired)
		_timer.start()
	# Apply rotation to face direction
	rotation = direction.angle() + PI * 0.5  # sprite faces down by default


func launch(from_pos: Vector2, dir: Vector2) -> void:
	global_position = from_pos
	direction = dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT
	rotation = direction.angle() + PI * 0.5


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	position += direction * speed * delta


func _on_lifetime_expired() -> void:
	_die()


func _die() -> void:
	_is_dead = true
	queue_free()
