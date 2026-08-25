##============================================================================##
#  selector.gd — Runs children left-to-right, succeeds if any child succeeds     #
##============================================================================##

class_name Selector
extends CompositeNode

func _tick(delta: float) -> int:
	for child in get_children():
		if child is BehaviorTreeNode:
			var child_status: int = child._tick(delta)
			if child_status == Status.SUCCESS:
				return Status.SUCCESS
			if child_status == Status.RUNNING:
				return Status.RUNNING
	return Status.FAILURE