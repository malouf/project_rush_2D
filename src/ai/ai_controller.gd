##============================================================================##
# 
#  ai_controller.gd — Attaches behavior tree to a hero for AI control            #
##============================================================================##

class_name AIController
extends Node

@onready var _hero: BaseHero = null
@export var target_team: int = 1  # Default enemy team
@export var detection_range: float = 1000.0
@export var attack_range: float = 200.0
@export var flee_health_threshold: float = 0.25
@export var behavior_tree: BehaviorTree = null

var _enemies: Array = []
var _update_timer: float = 0.0
var _update_interval: float = 0.5  # Update target list every 0.5s


func _ready() -> void:
	_hero = get_parent()
	if _hero == null:
		push_error("AIController must be child of a BaseHero")
		return
	if behavior_tree == null:
		behavior_tree = BehaviorTree.new()
	_setup_default_behavior_tree()


func _setup_default_behavior_tree() -> void:
	# Simple AI: 
	# Selector: 
	#   Sequence: Flee if low health
	#   Sequence: Attack if target in range
	#   Sequence: Wander/patrol
	var root = Selector.new()
	behavior_tree.add_child(root)
	
	# Flee sequence
	var flee_seq = Sequence.new()
	root.add_child(flee_seq)
	var low_hp = LowHealthCondition.new()
	low_hp.threshold = flee_health_threshold
	flee_seq.add_child(low_hp)
	var flee_action = FleeFromTargetAction.new()
	flee_seq.add_child(flee_action)
	
	# Attack sequence
	var attack_seq = Sequence.new()
	root.add_child(attack_seq)
	var in_range = InRangeOfTargetCondition.new()
	in_range.range = attack_range
	attack_seq.add_child(in_range)
	var attack_action = MeleeAttackAction.new()
	attack_seq.add_child(attack_action)
	
	# Patrol/sequence (placeholder for now)
	var patrol_seq = Sequence.new()
	root.add_child(patrol_seq)
	var idle = ActionNode.new()  # Do nothing for now
	patrol_seq.add_child(idle)


func _process(delta: float) -> void:
	_update_timer -= delta
	if _update_timer <= 0.0:
		_update_timer = _update_interval
		_update_target_list()
	_update_behavior_tree_targets()
	behavior_tree.tick(delta)


func _update_target_list() -> void:
	_enemies.clear()
	if get_tree() == null:
		return
	var heroes = get_tree().get_nodes_in_group("heroes")
	for h in heroes:
		if h is BaseHero:
			var bh: BaseHero = h
			if bh.team_id != _hero.team_id and not bh.is_dead:
				_enemies.append(bh)


func _update_behavior_tree_targets() -> void:
	if _enemies.is_empty():
		return
	# Find closest enemy
	var closest: BaseHero = null
	var best_dist: float = INF
	for enemy in _enemies:
		var dist: float = _hero.global_position.distance_to(enemy.global_position)
		if dist < best_dist:
			best_dist = dist
			closest = enemy
	if closest == null:
		return
	# Set target on all nodes that need it
	_set_recursive_target(behavior_tree, closest)


func _set_recursive_target(node: Node, target: BaseHero) -> void:
	if node == null:
		return
	if node is InRangeOfTargetCondition or node is LowHealthCondition or node is HasTargetCondition or node is MoveTowardTargetAction or node is MeleeAttackAction or node is FleeFromTargetAction:
		node.target = target
	for child in node.get_children():
		_set_recursive_target(child, target)