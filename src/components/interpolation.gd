##============================================================================##
#  interpolation.gd — Smooth visual interpolation between physics frames         #
#                                                                                #
#  Place this script on a child Node2D of the hero.  The hero's physics body     #
#  moves at 60Hz, but rendering can run at 120Hz.  This script lerps the         #
#  visual between the previous physics position and the current physics         #
#  position, producing fluid motion at the higher rendering rate.                #
#                                                                                #
#  Adapted from: Godot docs on physics_interpolation, librerama Camera2D/        #
#  Player separation, multiplayer_bomber client-side prediction.                #
##============================================================================##

class_name Interpolation
extends Node2D

@export var target: Node2D
@export_range(0.0, 1.0, 0.01) var smoothing: float = 1.0
@export_range(0.0, 1.0, 0.01) var interpolation_offset: float = 0.5

var _previous_target_position: Vector2
var _current_target_position: Vector2
var _has_baseline: bool = false


func _ready() -> void:
	if target == null:
		var parent: Node = get_parent()
		if parent is Node2D and parent != self:
			target = parent
	_update_targets()


func _physics_process(_delta: float) -> void:
	_previous_target_position = _current_target_position
	if target:
		_current_target_position = target.global_position
	_has_baseline = true


func _process(_delta: float) -> void:
	if not _has_baseline or target == null:
		return
	var physics_step: float = 1.0 / Engine.physics_ticks_per_second
	var physics_offset: float = (Time.get_ticks_usec() % int(physics_step * 1_000_000)) / (physics_step * 1_000_000)
	var t: float = clamp(physics_offset + interpolation_offset, 0.0, 1.0)
	var lerped: Vector2 = _previous_target_position.lerp(_current_target_position, t)
	if smoothing < 1.0:
		lerped = global_position.lerp(lerped, smoothing)
	global_position = lerped


func snap_to_target() -> void:
	if target:
		_previous_target_position = target.global_position
		_current_target_position = target.global_position
		global_position = target.global_position
		_has_baseline = true


func _update_targets() -> void:
	if target:
		_previous_target_position = target.global_position
		_current_target_position = target.global_position
		_has_baseline = true
