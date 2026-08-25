##============================================================================##
#  actions.gd — Concrete action nodes for bot AI                                 #
##============================================================================##

## Move the controlled hero toward the target
class_name MoveTowardTargetAction
extends ActionNode

@export var target: BaseHero = null
@export var speed_multiplier: float = 1.0
@export var arrival_radius: float = 8.0

func _tick(delta: float) -> int:
	if target == null:
		return Status.FAILURE
	var hero: BaseHero = _find_controlled_hero()
	if hero == null or hero.is_dead:
		return Status.FAILURE
	var to_target: Vector2 = target.global_position - hero.global_position
	var dist: float = to_target.length()
	if dist <= arrival_radius:
		return Status.SUCCESS
	var dir: Vector2 = to_target.normalized()
	hero.global_position += dir * hero.SPEED * speed_multiplier * delta
	# Update facing
	hero.facing_direction = dir
	hero.velocity_direction = dir
	return Status.RUNNING

func _find_controlled_hero() -> BaseHero:
	var n: Node = get_parent()
	while n:
		if n is BaseHero:
			return n
		n = n.get_parent()
	return null


## Attack the target with melee
class_name MeleeAttackAction
extends ActionNode

@export var target: BaseHero = null
@export var damage: int = 30
@export var cooldown: float = 1.0

var _cooldown_timer: float = 0.0

func _tick(delta: float) -> int:
	_cooldown_timer = max(0.0, _cooldown_timer - delta)
	if _cooldown_timer > 0.0:
		return Status.RUNNING
	if target == null or target.is_dead:
		return Status.FAILURE
	var hero: BaseHero = _find_controlled_hero()
	if hero == null:
		return Status.FAILURE
	# Apply damage
	var payload: DamagePayload = DamagePayload.new()
	payload.amount = damage
	payload.damage_type = &"melee"
	payload.shooter_id = hero.team_id
	payload.shooter_team = hero.team_id
	payload.knockback = (target.global_position - hero.global_position).normalized() * 80.0
	payload.hit_position = target.global_position
	payload.timestamp = Time.get_ticks_msec()
	target.hurtbox.hurt_received.emit(payload)
	_cooldown_timer = cooldown
	return Status.SUCCESS

func _find_controlled_hero() -> BaseHero:
	var n: Node = get_parent()
	while n:
		if n is BaseHero:
			return n
		n = n.get_parent()
	return null


## Pick a target (closest enemy in range)
class_name SelectTargetAction
extends ActionNode

@export var max_range: float = 800.0

var _selected_target: BaseHero = null

func _tick(_delta: float) -> int:
	var hero: BaseHero = _find_controlled_hero()
	if hero == null:
		return Status.FAILURE
	# Find closest enemy
	var best: BaseHero = null
	var best_dist: float = INF
	for candidate in hero.get_tree().get_nodes_in_group("heroes"):
		if candidate == hero:
			continue
		if not candidate is BaseHero:
			continue
		var bh: BaseHero = candidate
		if bh.is_dead or bh.team_id == hero.team_id:
			continue
		var dist: float = hero.global_position.distance_to(bh.global_position)
		if dist <= max_range and dist < best_dist:
			best = bh
			best_dist = dist
	_selected_target = best
	# Communicate to siblings
	_set_sibling_target(best)
	if best:
		return Status.SUCCESS
	return Status.FAILURE

func get_target() -> BaseHero:
	return _selected_target

func _set_sibling_target(t: BaseHero) -> void:
	# Set target on sibling nodes
	var parent: Node = get_parent()
	if parent:
		for sibling in parent.get_children():
			if sibling == self:
				continue
			if sibling is ConditionNode and sibling.has_method("set_target"):
				sibling.set("target", t)
			elif sibling is ActionNode and sibling.has_method("set_target"):
				sibling.set("target", t)

func _find_controlled_hero() -> BaseHero:
	var n: Node = get_parent()
	while n:
		if n is BaseHero:
			return n
		n = n.get_parent()
	return null


## Flee from the target
class_name FleeFromTargetAction
extends ActionNode

@export var target: BaseHero = null
@export var flee_distance: float = 300.0

func _tick(delta: float) -> int:
	if target == null:
		return Status.FAILURE
	var hero: BaseHero = _find_controlled_hero()
	if hero == null or hero.is_dead:
		return Status.FAILURE
	var away: Vector2 = (hero.global_position - target.global_position).normalized()
	hero.global_position += away * hero.SPEED * 1.2 * delta
	# Update facing (facing away from target)
	hero.facing_direction = away
	hero.velocity_direction = away
	return Status.RUNNING

func _find_controlled_hero() -> BaseHero:
	var n: Node = get_parent()
	while n:
		if n is BaseHero:
			return n
		n = n.get_parent()
	return null