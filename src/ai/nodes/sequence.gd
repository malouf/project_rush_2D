##============================================================================##
#  sequence.gd — Runs children left-to-right, fails if any child fails            #
##============================================================================##

class_name Sequence
extends CompositeNode

func _tick(delta: float) -> int:
	for child in get_children():
		if child is BehaviorTreeNode:
			var child_status: int = child._tick(delta)
			if child_status == Status.FAILURE:
				return Status.FAILURE
			if child_status == Status.RUNNING:
				return Status.RUNNING
	return Status.SUCCESS