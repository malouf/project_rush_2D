##============================================================================##
#  GameManager.gd — Global game lifecycle manager                             #
#  Adapted from: librerama managers/game_manager/game_manager.gd               #
##============================================================================##

class_name GameManager
extends CanvasLayer

## Singleton access
static var instance: GameManager

## Signals
signal scene_switched
signal settings_applied

## Constants
const SETTINGS_PATH = "user://settings.cfg"
const FADE_SPEED = 0.3

## Settings
var settings: Dictionary = {
	"general": {
		"language": "en_US",
		"pause_focus_lost": true,
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
	},
	"controls": {
		"switch_touch_controls": false,
	},
	"accessibility": {
		"color_blind_mode": "none",
		"color_blind_strength": 0.0,
		"text_scale": 1.0,
		"screen_shake_scale": 1.0,
		"hit_stop_enabled": true,
	},
}

## State
var _switching_scene: bool = false
var _current_scene_name: String = ""

@onready var _fade_rect: ColorRect = $Fade

func _ready() -> void:
	instance = self
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	load_settings()
	apply_settings()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_apply_mute_if_focus_lost(false)
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if settings.general.pause_focus_lost:
				get_tree().paused = true
			_apply_mute_if_focus_lost(settings.general.mute_focus_lost)

func _apply_mute_if_focus_lost(mute: bool) -> void:
	AudioServer.set_bus_mute(0, mute)

func switch_scene(path: String) -> void:
	if _switching_scene:
		push_error("Scene switch already in progress.")
		return

	fade_in()
	_switching_scene = true
	ResourceLoader.load_threaded_request(path, "PackedScene")
	await scene_switched
	_switching_scene = false
	fade_out()

func load_scene_sync(path: String) -> void:
	"""Immediate scene switch with deferred call to avoid mid-frame issues."""
	call_deferred("_deferred_switch", path)

func _deferred_switch(path: String) -> void:
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	var scene = ResourceLoader.load(path) as PackedScene
	if scene:
		get_tree().root.add_child(scene.instantiate())
		get_tree().current_scene = get_tree().current_scene if get_tree().current_scene == null else get_tree().current_scene

func fade_in() -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween().set_parallel()
	tween.tween_property(_fade_rect, ^"modulate:a", 1.0, FADE_SPEED)
	tween.chain().tween_callback(emit_signal.bind("scene_switched"))

func fade_out() -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween().set_parallel()
	tween.tween_property(_fade_rect, ^"modulate:a", 0.0, FADE_SPEED)

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	if err != OK:
		return
	for section in settings.keys():
		if not config.has_section(section):
			continue
		for key in settings[section].keys():
			if config.has_section_key(section, key):
				settings[section][key] = config.get_value(section, key)

func save_settings() -> void:
	var config = ConfigFile.new()
	for section in settings.keys():
		for key in settings[section].keys():
			config.set_value(section, key, settings[section][key])
	var err = config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save settings. Error: %d" % err)

func apply_settings() -> void:
	# Audio
	for i in range(1, AudioServer.bus_count):
		var bus_name = AudioServer.get_bus_name(i).to_lower()
		if settings.audio.has(bus_name + "_volume"):
			var vol = settings.audio[bus_name + "_volume"]
			AudioServer.set_bus_volume_db(i, linear_to_db(vol))

	# Rendering
	if settings.accessibility.color_blind_mode != "none":
		_apply_color_blind_filter()

	emit_signal("settings_applied")
