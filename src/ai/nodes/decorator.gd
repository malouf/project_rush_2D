##============================================================================##
#  decorator.gd — Inverter decorator                                             #
##============================================================================##

class_name Inverter
extends BehaviorTreeNode

var _child: Node = null

func _ready() -> void:
	if get_child_count() > 0:
		_child = get_child(0)

func _tick(delta: float) -> int:
	if _child == null:
		return Status.FAILURE
	var child_result: int = _child._tick(delta)
	match child_result:
		Status.SUCCESS:
			return Status.FAILURE
		Status.FAILURE:
			return Status.SUCCESS
		Status.RUNNING:
			return Status.RUNNING
	return child_result