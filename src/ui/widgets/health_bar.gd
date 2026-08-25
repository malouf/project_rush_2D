##============================================================================##
#  health_bar.gd — Health bar UI widget                                        #
#  Adapted from: PlaneShooter HealthBar.gd                                     #
##============================================================================##

class_name HealthBar
extends Control

@export var health_component: HealthComponent:
	set(value):
		if health_component:
			health_component.health_changed.disconnect(_on_health_changed)
		health_component = value
		if health_component:
			health_component.health_changed.connect(_on_health_changed)
			_on_health_changed(health_component.current_health, health_component.current_health, 0)

@export var team_color: Color = Color.RED
@export var show_overhealth: bool = true

@onready var _health_bg: ColorRect = $Background
@onready var _health_fill: ColorRect = $Fill
@onready var _overhealth_fill: ColorRect = $Overhealth
@onready var _label: Label = $Label

func _ready() -> void:
	if not health_component:
		visible = false
		return
	modulate = team_color

func _on_health_changed(old_value: int, new_value: int, overhealth: int) -> void:
	var pct: float = float(new_value) / float(health_component.max_health)
	pct = clamp(pct, 0.0, 1.0)
	_health_fill.anchor_right = pct
	_health_fill.modulate = Color(0.2, 1.0, 0.2, 1.0) if pct > 0.5 else Color(1.0, 0.2, 0.2, 1.0)

	if show_overhealth and overhealth > 0:
		var over_pct: float = (float(new_value + overhealth) / float(health_component.max_health))
		over_pct = clamp(over_pct, 0.0, 1.0)
		_overhealth_fill.anchor_right = over_pct
		_overhealth_fill.visible = true
	else:
		_overhealth_fill.visible = false

	_label.text = "%d / %d" % [new_value, health_component.max_health]
