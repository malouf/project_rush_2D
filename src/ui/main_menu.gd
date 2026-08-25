##============================================================================##
#  main_menu.gd — Simple lobby screen with host/join buttons                      #
#  Phase 3: Lobby networking                                                   #
##============================================================================##

extends CanvasLayer

@onready var host_btn: Button = $VBox/HostBtn
@onready var join_btn: Button = $VBox/JoinBtn
@onready var ip_edit: LineEdit = $VBox/IPEdit
@onready var status_label: Label = $VBox/StatusLabel

func _ready() -> void:
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	
	# Connect network signals
	GameNetwork.connection_succeeded.connect(_on_connection_succeeded)
	GameNetwork.connection_failed.connect(_on_connection_failed)
	GameNetwork.server_disconnected.connect(_on_server_disconnected)
	GameNetwork.all_players_loaded.connect(_on_all_players_loaded)

	ip_edit.text_submitted.connect(_on_ip_submitted)


func _on_host_pressed() -> void:
	status_label.text = "Starting server..."
	host_btn.disabled = true
	join_btn.disabled = true
	
	var error = GameNetwork.host_game()
	if error != OK:
		status_label.text = "Failed to host: %s" % error
		host_btn.disabled = false
		join_btn.disabled = false
		return
	
	status_label.text = "Server started. Waiting for players..."


func _on_join_pressed() -> void:
	var ip = ip_edit.text.strip_edges()
	if ip.is_empty():
		ip_edit.text = "127.0.0.1"
		ip = "127.0.0.1"
	
	status_label.text = "Connecting to %s..." % ip
	host_btn.disabled = true
	join_btn.disabled = true
	
	var error = GameNetwork.join_game(ip)
	if error != OK:
		status_label.text = "Failed to connect: %s" % error
		host_btn.disabled = false
		join_btn.disabled = false


func _on_ip_submitted(_text: String) -> void:
	_on_join_pressed()


func _on_connection_succeeded() -> void:
	status_label.text = "Connected! Waiting for game start..."
	GameNetwork.begin_game()


func _on_connection_failed() -> void:
	status_label.text = "Connection failed."
	host_btn.disabled = false
	join_btn.disabled = false


func _on_server_disconnected() -> void:
	status_label.text = "Disconnected from server."
	host_btn.disabled = false
	join_btn.disabled = false


func _on_all_players_loaded() -> void:
	status_label.text = "All players ready!"
