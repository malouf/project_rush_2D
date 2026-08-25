##============================================================================##
#  cast_input.gd — Manages input for skills (tap, drag-to-aim, target lock)      #
#  Phase 5: Casting & Accessibility                                              #
##============================================================================##

extends Node

@export var local_hero: BaseHero

## Skill slots
@onready var skill_slot_1: BaseSkill = preload("res://src/skills/melee_slash.tres")
@onready var skill_slot_2: BaseSkill = preload("res://src/skills/fireball.tres")

## Cast state
var _is_casting: bool = false
var _cast_skill: BaseSkill = null
var _cast_start_pos: Vector2 = Vector2.ZERO
var _cast_start_time: int = 0
var _current_cast_dir: Vector2 = Vector2.RIGHT

## Aim-assist (accessibility)
@export var aim_assist_enabled: bool = true
@export var aim_assist_snap_angle: float = 0.3  # ~17 degrees
@export var aim_assist_max_range: float = 600.0

## UI references (set by parent scene)
@onready var aim_indicator: AimIndicator = get_node_or_null("/root/World/UI/AimIndicator")


func _ready() -> void:
	# Default to player 1 hero if not set
	if local_hero == null:
		var heroes = get_tree().get_nodes_in_group("heroes")
		if heroes.size() > 0:
			local_hero = heroes[0]


func _unhandled_input(event: InputEvent) -> void:
	if local_hero == null or not local_hero.is_local_authority or local_hero.is_dead:
		return

	# Mouse/touch press = begin cast
	if event.is_action_pressed("tap_to_cast"):
		_begin_cast(event)

	# Drag = update aim direction
	if event.is_action_pressed("drag_to_aim") and _is_casting:
		_update_cast_aim(event)

	# Mouse/touch release = execute cast
	if event.is_action_released("tap_to_cast") and _is_casting:
		_finish_cast(event)


func _begin_cast(event: InputEvent) -> void:
	# Determine which skill to use based on input
	# For now, use skill slot 1 (melee)
	_cast_skill = skill_slot_1
	_cast_skill.update_cooldown(0)
	if not _cast_skill.can_cast(local_hero):
		return
	_is_casting = true
	_cast_start_pos = _get_input_position(event)
	_cast_start_time = Time.get_ticks_msec()
	_current_cast_dir = _get_cast_direction(event)

	# Initialize the skill (charge start)
	_cast_skill._is_charging = true
	_cast_skill._charge_start_time = _cast_start_time
	_cast_skill._charge_start_position = local_hero.global_position

	# Show aim indicator
	if aim_indicator:
		aim_indicator.show_aim(_cast_start_pos, _current_cast_dir, 0.0)


func _update_cast_aim(event: InputEvent) -> void:
	if not _is_casting or _cast_skill == null:
		return
	_current_cast_dir = _get_cast_direction(event)
	var charge_time: float = (Time.get_ticks_msec() - _cast_start_time) / 1000.0
	var charge_factor: float = clamp(charge_time / _cast_skill.drag_max_time, 0.0, 1.0)
	if aim_indicator:
		aim_indicator.show_aim(_cast_start_pos, _current_cast_dir, charge_factor)


func _finish_cast(event: InputEvent) -> void:
	if not _is_casting or _cast_skill == null:
		return
	# Execute the cast
	var release_pos: Vector2 = _get_input_position(event)
	_cast_skill.on_skill_released(local_hero, release_pos)
	_cast_skill._is_charging = false

	# Reset state
	_is_casting = false
	_cast_skill = null
	if aim_indicator:
		aim_indicator.hide_aim()


func _get_input_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	return Vector2.ZERO


func _get_cast_direction(event: InputEvent) -> Vector2:
	var input_pos: Vector2 = _get_input_position(event)
	if input_pos == Vector2.ZERO:
		return _current_cast_dir

	# Convert screen position to world
	var camera: Camera2D = get_viewport().get_camera_2d()
	var world_pos: Vector2 = input_pos
	if camera:
		world_pos = camera.get_screen_center_position() + (input_pos - get_viewport().get_visible_rect().size * 0.5) / camera.zoom.x

	# Direction from hero to input
	var dir: Vector2 = (world_pos - local_hero.global_position).normalized()

	# Apply aim-assist
	if aim_assist_enabled:
		dir = _apply_aim_assist(dir)

	return dir


func _apply_aim_assist(direction: Vector2) -> Vector2:
	# Find nearest enemy in the cone of aim_assist_snap_angle
	var best_target: BaseHero = null
	var best_dot: float = cos(aim_assist_snap_angle)
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = local_hero.global_position + direction * aim_assist_max_range * 0.5
	query.collision_mask = 1  # hero body layer
	var results = space.intersect_point(query, 16)
	for r in results:
		var collider = r["collider"]
		if collider is BaseHero and collider != local_hero and collider.team_id != local_hero.team_id:
			var to_target: Vector2 = (collider.global_position - local_hero.global_position).normalized()
			var dot: float = to_target.dot(direction)
			if dot > best_dot:
				best_dot = dot
				best_target = collider
	if best_target:
		direction = (best_target.global_position - local_hero.global_position).normalized()
	return direction
