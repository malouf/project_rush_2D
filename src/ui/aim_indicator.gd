##============================================================================##
#  aim_indicator.gd — Visual drag-to-aim indicator with charge bar               #
#  Phase 5: Casting & Accessibility                                              #
##============================================================================##

extends Node2D

@export var line_color: Color = Color(0.0, 0.8, 1.0, 0.8)
@export var charge_color: Color = Color(1.0, 0.3, 0.1, 0.9)
@export var font_size: int = 18

@onready var _line: Line2D = $Line2D
@onready var _charge_bar: ProgressBar = $ChargeBar
@onready var _label: Label = $Label

var _visible: bool = false
var _start_pos: Vector2 = Vector2.ZERO
var _direction: Vector2 = Vector2.RIGHT
var _charge: float = 0.0


func _ready() -> void:
	hide()


func show_aim(start_pos: Vector2, direction: Vector2, charge: float) -> void:
	_visible = true
	_start_pos = start_pos
	_direction = direction
	_charge = charge
	_update_visuals()
	show()


func hide_aim() -> void:
	_visible = false
	hide()


func _update_visuals() -> void:
	if not _visible:
		return
	
	# Line from start to direction * max range
	var max_range: float = 600.0
	var end_pos: Vector2 = _start_pos + _direction * max_range * _charge
	_line.points = PackedVector2Array([Vector2.ZERO, end_pos - _start_pos])
	_line.default_color = line_color.lerp(charge_color, _charge)

	# Charge bar
	_charge_bar.value = _charge * 100

	# Label with distance and charge
	_label.text = "%dm / %d%%" % [int(max_range * _charge), int(_charge * 100)]


func _process(delta: float) -> void:
	if _visible:
		# Pulse the charge bar
		_charge_bar.modulate = Color(1, 1, 1, 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01))