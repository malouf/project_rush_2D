##============================================================================##
#  melee_slash.gd — Test melee skill (placeholder graphics, no scene file)        #
#  Phase 4: Combat - simplest possible melee slash for testing                  #
##============================================================================##

class_name MeleeSlash
extends Node2D

@export var damage: int = 30
@export var cooldown: float = 0.8
@export var range: float = 48.0
@export var arc_degrees: float = 90.0

var _owner: BaseHero = null
var _cooldown_timer: float = 0.0
var _is_on_cooldown: bool = false
var _slash_angle: float = 0.0
var _slash_progress: float = 0.0

func setup(owner: BaseHero) -> void:
	_owner = owner


func can_cast() -> bool:
	return not _is_on_cooldown and _owner != null


func execute(target_dir: Vector2) -> void:
	if not can_cast():
		return
	_is_on_cooldown = true
	_cooldown_timer = cooldown
	_slash_angle = target_dir.angle()
	_slash_progress = 0.0
	_visual_slash(target_dir)
	_apply_damage(target_dir)
	_finish()


func _visual_slash(direction: Vector2) -> void:
	# Placeholder: create a Polygon2D arc in front of the hero.
	var arc = Polygon2D.new()
	arc.name = "SlashArc"
	var points = PackedVector2Array()
	var segments = 12
	var half_arc = deg_to_rad(arc_degrees * 0.5)
	var angle_start = _slash_angle - half_arc
	for i in range(segments + 1):
		var a = lerp(angle_start, angle_start + half_arc * 2.0, float(i) / float(segments))
		points.append(Vector2(cos(a), sin(a)) * range)
	points.append(Vector2.ZERO)  # center

	arc.set_polygon(points)
	arc.color = Color(1.0, 0.3, 0.1, 0.5)
	arc.z_index = 10
	_owner.get_parent().add_child(arc)

	var tween = _owner.create_tween()
	tween.tween_method(func(p: float) -> void:
		var alpha = 0.5 * (1.0 - p)
		if arc:
			arc.color.a = alpha
	, 0.0, 1.0, 0.2)
	tween.tween_callback(func() -> void:
		if arc and arc.is_inside_tree():
			arc.queue_free()
	)


func _apply_damage(direction: Vector2) -> void:
	var space = _owner.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	var center = _owner.global_position
	var spread = deg_to_rad(arc_degrees * 0.5)
	query.position = center
	query.collision_mask = 4  # hurtbox layer

	var results = space.intersect_point(query, 8)
	for result in results:
		var collider = result["collider"]
		if collider is HurtBox2D:
			if collider.team_id != _owner.team_id:
				var payload: DamagePayload = DamagePayload.new()
				payload.shooter_id = _owner.team_id
				payload.shooter_team = _owner.team_id
				payload.amount = damage
				payload.damage_type = &"melee"
				payload.knockback = direction.normalized() * 80.0
				payload.is_critical = false
				payload.hit_position = collider.global_position
				payload.timestamp = Time.get_ticks_msec()
				collider.hurt_received.emit(payload)


func _finish() -> void:
	_is_on_cooldown = false


func _physics_process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_is_on_cooldown = false
			_cooldown_timer = 0.0
