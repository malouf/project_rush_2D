##============================================================================##
#  interpolation.gd — Visual sprite interpolation for 120 FPS rendering         #
#  Adapted from: Document "Interpolation" + Godot physics_interpolation        #
##============================================================================##

class_name Interpolation
extends Sprite2D

var _previous_position: Vector2

func _ready() -> void:
	_previous_position = position
	set_physics_process_internal(true)

func _physics_process(delta: float) -> void:
	_previous_position = get_parent().get("position") if get_parent() is Node2D else _previous_position

func _process(delta: float) -> void:
	var parent_pos: Vector2 = get_parent().position if get_parent() is Node2D else position
	var factor: float = Engine.get_physics_frames_to_process() * Engine.get_physics_process_delta() - delta
	factor = clamp(factor, 0.0, 1.0)
	position = _previous_position.lerp(parent_pos, factor)
