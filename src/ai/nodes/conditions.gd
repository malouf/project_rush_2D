##============================================================================##
#  conditions.gd — Concrete condition nodes for bot AI                            #
##============================================================================##

## Checks if a target hero is in range of the AI's controlled hero
class_name InRangeOfTargetCondition
extends ConditionNode

@export var range: float = 200.0
@export var target: BaseHero = null

func _tick(_delta: float) -> int:
	if target == null or not target.is_inside_tree():
		return Status.FAILURE
	if target.is_dead:
		return Status.FAILURE
	var hero: BaseHero = _find_controlled_hero()
	if hero == null:
		return Status.FAILURE
	var dist: float = hero.global_position.distance_to(target.global_position)
	if dist <= range:
		return Status.SUCCESS
	return Status.FAILURE

func _find_controlled_hero() -> BaseHero:
	var n: Node = get_parent()
	while n:
		if n is BaseHero:
			return n
		n = n.get_parent()
	return null


## Checks if controlled hero's health is below threshold
class_name LowHealthCondition
extends ConditionNode

@export var threshold: float = 0.3

func _tick(_delta: float) -> int:
	var hero: BaseHero = _find_controlled_hero()
	if hero == null:
		return Status.FAILURE
	var hp: HealthComponent = hero.health_component
	if hp == null:
		return Status.FAILURE
	var hp_percent: float = hp.get_health_percent()
	if hp_percent <= threshold:
		return Status.SUCCESS
	return Status.FAILURE

func _find_controlled_hero() -> BaseHero:
	var n: Node = get_parent()
	while n:
		if n is BaseHero:
			return n
		n = n.get_parent()
	return null


## Checks if there's a valid target
class_name HasTargetCondition
extends ConditionNode

@export var target: BaseHero = null

func _tick(_delta: float) -> int:
	if target == null:
		return Status.FAILURE
	if not target.is_inside_tree():
		return Status.FAILURE
	if target.is_dead:
		return Status.FAILURE
	return Status.SUCCESS


## Checks if hero is alive
class_name IsAliveCondition
extends ConditionNode

func _tick(_delta: float) -> int:
	var hero: BaseHero = _find_controlled_hero()
	if hero == null:
		return Status.FAILURE
	if hero.is_dead:
		return Status.FAILURE
	return Status.SUCCESS

func _find_controlled_hero() -> BaseHero:
	var n: Node = get_parent()
	while n:
		if n is BaseHero:
			return n
		n = n.get_parent()
	return null