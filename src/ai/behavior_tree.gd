##============================================================================##
#  behavior_tree.gd — Behavior tree controller                                  #
#  Simple selector/decorator system for bot AI                                  #
##============================================================================##

class_name BehaviorTree
extends Node

enum Status {
	SUCCESS,
	FAILURE,
	RUNNING
}

var _root: Node = null
var _elapsed: float = 0.0

func _ready() -> void:
	# Find root composite node (first child that's a CompositeNode)
	for child in get_children():
		if child is CompositeNode:
			_root = child
			break


func tick(delta: float) -> Status:
	_elapsed = delta
	if _root:
		return _root._tick(delta)
	return Status.FAILURE


func reset() -> void:
	_elapsed = 0.0
	_root = null