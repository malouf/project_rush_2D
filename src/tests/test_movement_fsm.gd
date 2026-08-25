extends GutTest

var _fsm: MovementFSM

func before_each():
	_fsm = MovementFSM.new()
	add_child_autofree(_fsm)


func after_each():
	_fsm.free()


func test_initial_state_is_idle():
	assert_eq(_fsm.current_state, MovementFSM.State.IDLE)


func test_input_transitions_to_move():
	_fsm.set_input(Vector2(1, 0))
	assert_eq(_fsm.current_state, MovementFSM.State.MOVE)


func test_no_input_stays_in_idle():
	_fsm.set_input(Vector2.ZERO)
	assert_eq(_fsm.current_state, MovementFSM.State.IDLE)


func test_stun_ignores_input():
	_fsm.enter_stun()
	assert_true(_fsm.is_stunned())
	_fsm.set_input(Vector2(1, 0))
	assert_eq(_fsm.current_state, MovementFSM.State.STUN)


func test_exit_stun_returns_to_idle():
	_fsm.enter_stun()
	_fsm.exit_stun()
	assert_false(_fsm.is_stunned())
	assert_eq(_fsm.current_state, MovementFSM.State.IDLE)


func test_is_moving():
	_fsm.set_input(Vector2(1, 0))
	assert_true(_fsm.is_moving())


func test_stunned_blocked():
	_fsm.enter_stun()
	_fsm.set_input(Vector2(1, 0))
	assert_eq(_fsm.current_state, MovementFSM.State.STUN)


func test_state_changed_signal():
	var from = -1
	var to = -1
	_fsm.state_changed.connect(func(f, t): from = f; to = t)
	_fsm.set_input(Vector2(1, 0))
	assert_eq(from, MovementFSM.State.IDLE)
	assert_eq(to, MovementFSM.State.MOVE)


func test_same_state_no_transition():
	_fsm.set_input(Vector2(1, 0))
	var count = 0
	_fsm.state_changed.connect(func(_f, _t): count += 1)
	_fsm.set_input(Vector2(0.5, 0.1))
	assert_eq(count, 0)
