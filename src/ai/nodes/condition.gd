##============================================================================##
#  condition.gd — Base condition node (returns SUCCESS/FAILURE)                  #
##============================================================================##

class_name ConditionNode
extends BehaviorTreeNode

## Override this in subclasses to implement custom logic.
func _tick(_delta: float) -> int:
	return Status.FAILURE