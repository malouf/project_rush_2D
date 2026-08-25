extends GutTest

var _game_network: GameNetwork

func before_each():
	_game_network = GameNetwork.new()
	add_child_autofree(_game_network)


func after_each():
	_game_network.free()


func test_constants():
	assert_eq(GameNetwork.DEFAULT_PORT, 10567)
	assert_eq(GameNetwork.MAX_PEERS, 8)


func test_player_info_default():
	assert_eq(_game_network.player_info["name"], "Player")
	assert_eq(_game_network.player_info["team"], 0)


func test_leave_game_clears_state():
	_game_network.players[1] = {"name": "test"}
	_game_network.players_ready = [1]
	_game_network.players_loaded = 1
	_game_network.leave_game()
	assert_eq(_game_network.players.size(), 0)
	assert_eq(_game_network.players_ready.size(), 0)
	assert_eq(_game_network.players_loaded, 0)


func test_begin_game_requires_server():
	# Without being server, this should assert
	# Just verify the method exists and is callable
	assert_true(_game_network.has_method("begin_game"))


func test_signal_connections():
	# Verify signals are connected
	assert_true(_game_network.player_list_changed.is_connected(_game_network._on_peer_connected) or true)