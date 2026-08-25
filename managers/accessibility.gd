##============================================================================##
#  accessibility.gd — Mobile accessibility utilities                           #
#  Provides high contrast, font scaling, screen reader labels                  #
##============================================================================##

class_name AccessibilityManagerBase
extends Node

signal high_contrast_changed(enabled: bool)
signal font_scale_changed(scale: float)
signal screen_reader_enabled(enabled: bool)

## Default mobile-friendly values
@export var default_font_scale: float = 1.2
@export var high_contrast_palette: Dictionary = {
	"background": Color(0, 0, 0),
	"foreground": Color(1, 1, 1),
	"accent": Color(0, 0.8, 1)
}

## Runtime state
var _high_contrast: bool = false
var _font_scale: float = 1.0
var _screen_reader_enabled: bool = false


func _ready() -> void:
	# Load from user settings if available
	_load_settings()


func set_high_contrast(enabled: bool) -> void:
	if _high_contrast == enabled:
		return
	_high_contrast = enabled
	_apply_palette()
	high_contrast_changed.emit(enabled)
	_save_settings()


func is_high_contrast_enabled() -> bool:
	return _high_contrast


func set_font_scale(scale: float) -> void:
	_font_scale = clamp(scale, 0.5, 3.0)
	font_scale_changed.emit(_font_scale)
	_save_settings()


func get_font_scale() -> float:
	return _font_scale * default_font_scale


func set_screen_reader_enabled(enabled: bool) -> void:
	if _screen_reader_enabled == enabled:
		return
	_screen_reader_enabled = enabled
	screen_reader_enabled.emit(enabled)
	_save_settings()


func is_screen_reader_enabled() -> bool:
	return _screen_reader_enabled


## Helper for UI elements to apply accessibility
func apply_accessibility_to_control(control: Control) -> void:
	if not control:
		return
	if _high_contrast:
		# Force high contrast colors
		control.theme_override_colors["font_color"] = high_contrast_palette["foreground"]
		control.theme_override_colors["font_color_hover"] = high_contrast_palette["accent"]
		control.theme_override_colors["font_color_pressed"] = high_contrast_palette["accent"] * 0.8
		control.theme_override_colors["bg_color"] = high_contrast_palette["background"]
	else:
		# Clear overrides
		control.theme_override_colors.clear()
	
	# Scale font
	var theme = Control.new().get_theme()
	if theme:
		var font_size = theme.get_font_size("font", "Font")
		theme.set_font_size("font", "Font", int(font_size * get_font_scale()))
		control.theme = theme


func _apply_palette() -> void:
	# Apply to all controls in the tree (simplified - in production would use theme)
	var root = get_tree().root
	if root:
		_apply_palette_to_node(root)


func _apply_palette_to_node(node: Node) -> void:
	if node is Control:
		apply_accessibility_to_control(node)
	for child in node.get_children():
		_apply_palette_to_node(child)


func _load_settings() -> void:
	var save = FileAccess.open("user://accessibility.save", FileAccess.READ)
	if save:
		var line = save.get_line()
		_high_contrast = line == "true" or line == "1" or line == "yes"
		_font_scale = line.to_float()
		var line2 = save.get_line()
		_screen_reader_enabled = line2 == "true" or line2 == "1" or line2 == "yes"
		save.close()


func _save_settings() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		var save = FileAccess.open("user://accessibility.save", FileAccess.WRITE)
		if save:
			save.store_line(str(_high_contrast))
			save.store_line(str(_font_scale))
			save.store_line(str(_screen_reader_enabled))
			save.close()