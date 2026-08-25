extends GutTest

var _cast_input: Node

func before_each():
	_cast_input = preload("res://src/ui/cast_input.gd").new()
	add_child_autofree(_cast_input)


func after_each():
	_cast_input.free()


func test_cast_state_initial():
	assert_false(_cast_input._is_casting)
	assert_null(_cast_input._cast_skill)


func test_aim_assist_default():
	assert_true(_cast_input.aim_assist_enabled)


func test_aim_assist_snap_angle():
	assert_true(_cast_input.aim_assist_snap_angle > 0)


func test_aim_assist_max_range():
	assert_true(_cast_input.aim_assist_max_range > 0)