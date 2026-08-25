##============================================================================##
#  action.gd — Base action node (returns SUCCESS/FAILURE/RUNNING)                 #
##============================================================================##

class_name ActionNode
extends BehaviorTreeNode

## Override this in subclasses to implement custom logic.
func _tick(_delta: float) -> int:
	return Status.FAILURE