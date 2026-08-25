##============================================================================##
#  main_menu.gd — Main menu with host/join + settings + Kenney assets          #
#  Phase 8: UI Polish                                                          #
##============================================================================##

extends CanvasLayer

@onready var host_btn: Button = $Panel/VBox/HostBtn
@onready var join_btn: Button = $Panel/VBox/JoinBtn
@onready var ip_edit: LineEdit = $Panel/VBox/IPEdit
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var settings_btn: Button = $Panel/VBox/SettingsBtn

## Settings popup
var _settings_popup: Window = null

func _ready() -> void:
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	ip_edit.text_submitted.connect(_on_ip_submitted)
	settings_btn.pressed.connect(_on_settings_pressed)
	
	# Connect network signals
	GameNetwork.connection_succeeded.connect(_on_connection_succeeded)
	GameNetwork.connection_failed.connect(_on_connection_failed)
	GameNetwork.server_disconnected.connect(_on_server_disconnected)
	GameNetwork.all_players_loaded.connect(_on_all_players_loaded)
	
	# Apply accessibility settings
	if Accessibility:
		Accessibility.high_contrast_changed.connect(_on_high_contrast_changed)


func _on_host_pressed() -> void:
	status_label.text = "Starting server..."
	status_label.modulate = Color(0.8, 0.9, 1.0)
	host_btn.disabled = true
	join_btn.disabled = true
	
	var error = GameNetwork.host_game()
	if error != OK:
		status_label.text = "Failed to host: %s" % error
		status_label.modulate = Color(1, 0.3, 0.3)
		host_btn.disabled = false
		join_btn.disabled = false
		return
	
	status_label.text = "Server started. Waiting for players..."
	# Switch to world scene
	get_tree().change_scene_to_file("res://scenes/world.tscn")


func _on_join_pressed() -> void:
	var ip = ip_edit.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
		ip_edit.text = ip
	
	status_label.text = "Connecting to %s..." % ip
	status_label.modulate = Color(0.8, 0.9, 1.0)
	host_btn.disabled = true
	join_btn.disabled = true
	
	var error = GameNetwork.join_game(ip)
	if error != OK:
		status_label.text = "Failed to connect: %s" % error
		status_label.modulate = Color(1, 0.3, 0.3)
		host_btn.disabled = false
		join_btn.disabled = false


func _on_ip_submitted(_text: String) -> void:
	_on_join_pressed()


func _on_settings_pressed() -> void:
	_show_settings()


func _show_settings() -> void:
	if _settings_popup:
		_settings_popup.show()
		return
	
	var popup = Window.new()
	popup.title = "Settings"
	popup.size = Vector2(400, 300)
	popup.mode = Window.MODE_WINDOW_CENTER_MAIN_SCREEN
	
	# Content
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(380, 280)
	
	# High contrast toggle
	var hc_toggle = CheckBox.new()
	hc_toggle.text = "High Contrast Mode"
	hc_toggle.button_pressed = Accessibility.is_high_contrast_enabled()
	hc_toggle.toggled.connect(func(toggled: bool) -> void:
		Accessibility.set_high_contrast(toggled)
	)
	vbox.add_child(hc_toggle)
	
	# Font scale slider
	var fs_label = Label.new()
	fs_label.text = "Font Scale: %.1f" % Accessibility.get_font_scale()
	var fs_slider = HSlider.new()
	fs_slider.min_value = 0.8
	fs_slider.max_value = 2.0
	fs_slider.value = Accessibility.get_font_scale() / 1.2
	fs_slider.step = 0.1
	fs_slider.value_changed.connect(func(val: float) -> void:
		Accessibility.set_font_scale(val)
		fs_label.text = "Font Scale: %.1f" % Accessibility.get_font_scale()
	)
	vbox.add_child(fs_label)
	vbox.add_child(fs_slider)
	
	# Screen reader toggle
	var sr_toggle = CheckBox.new()
	sr_toggle.text = "Screen Reader Mode"
	sr_toggle.button_pressed = Accessibility.is_screen_reader_enabled()
	sr_toggle.toggled.connect(func(toggled: bool) -> void:
		Accessibility.set_screen_reader_enabled(toggled)
	)
	vbox.add_child(sr_toggle)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func() -> void: popup.hide())
	vbox.add_child(close_btn)
	
	popup.add_child(vbox)
	add_child(popup)
	_settings_popup = popup


func _on_connection_succeeded() -> void:
	status_label.text = "Connected! Waiting for game start..."
	status_label.modulate = Color(0.3, 1.0, 0.3)


func _on_connection_failed() -> void:
	status_label.text = "Connection failed."
	status_label.modulate = Color(1, 0.3, 0.3)
	host_btn.disabled = false
	join_btn.disabled = false


func _on_server_disconnected() -> void:
	status_label.text = "Disconnected from server."
	status_label.modulate = Color(1, 0.3, 0.3)
	host_btn.disabled = false
	join_btn.disabled = false


func _on_all_players_loaded() -> void:
	status_label.text = "All players ready!"
	status_label.modulate = Color(0.3, 1.0, 0.3)


func _on_high_contrast_changed(enabled: bool) -> void:
	if enabled:
		modulate = Color(1.2, 1.2, 1.2, 1)
	else:
		modulate = Color(1, 1, 1, 1)