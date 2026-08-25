##============================================================================##
#  behavior_tree_node.gd — Base class for behavior tree nodes                  #
##============================================================================##

class_name BehaviorTreeNode
extends Node

enum Status {
	SUCCESS,
	FAILURE,
	RUNNING
}

func _tick(delta: float) -> int:
	return Status.FAILURE
