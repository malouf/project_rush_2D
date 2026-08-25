##============================================================================##
#  composite.gd — Selector and Sequence composite nodes                          #
##============================================================================##

class_name CompositeNode
extends Node

func _tick(delta: float) -> int:
	return Status.FAILURE