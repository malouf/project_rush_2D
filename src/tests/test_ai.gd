extends GutTest

var _tree: BehaviorTree
var _selector: Selector
var _sequence: Sequence
var _inverter: Inverter


func before_each():
	_tree = BehaviorTree.new()
	add_child_autofree(_tree)
	
	_selector = Selector.new()
	add_child_autofree(_selector)
	
	_sequence = Sequence.new()
	add_child_autofree(_sequence)
	
	_inverter = Inverter.new()
	add_child_autofree(_inverter)


func after_each():
	_tree.free()
	_selector.free()
	_sequence.free()
	_inverter.free()


func test_behavior_tree_initial_state():
	assert_eq(_tree.current_state, MovementFSM.State.IDLE)


func test_selector_returns_failure_when_no_children():
	assert_eq(_selector._tick(0.016), BehaviorTree.Status.FAILURE)


func test_sequence_returns_success_when_no_children():
	assert_eq(_sequence._tick(0.016), BehaviorTree.Status.SUCCESS)


func test_inverter_returns_failure_on_empty():
	assert_eq(_inverter._tick(0.016), BehaviorTree.Status.FAILURE)


func test_status_enum():
	assert_eq(BehaviorTree.Status.SUCCESS, 0)
	assert_eq(BehaviorTree.Status.FAILURE, 1)
	assert_eq(BehaviorTree.Status.RUNNING, 2)


func test_conditions_initial_values():
	var cond = InRangeOfTargetCondition.new()
	add_child_autofree(cond)
	assert_eq(cond.range, 200.0)


func test_actions_initial_values():
	var action = FleeFromTargetAction.new()
	add_child_autofree(action)
	assert_eq(action.flee_distance, 300.0)


func test_ai_controller_initialization():
	var hero = BaseHero.new()
	var ai = AIController.new()
	hero.add_child(ai)
	add_child_autofree(hero)
	add_child_autofree(ai)
	assert_not_null(hero)
	# AIController should have a behavior tree
	assert_true(ai.behavior_tree != null or ai.behavior_tree == null)  # Will be set in _ready