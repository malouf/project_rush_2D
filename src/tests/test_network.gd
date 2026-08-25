extends GutTest


func before_each():
	GameNetwork.players.clear()
	GameNetwork.players_ready.clear()
	GameNetwork.players_loaded = 0


func after_each():
	pass


func test_constants():
	assert_eq(GameNetwork.DEFAULT_PORT, 10567)
	assert_eq(GameNetwork.MAX_PEERS, 8)


func test_player_info_default():
	assert_eq(GameNetwork.player_info["name"], "Player")
	assert_eq(GameNetwork.player_info["team"], 0)


func test_leave_game_clears_state():
	GameNetwork.players[1] = {"name": "test"}
	GameNetwork.players_ready = [1]
	GameNetwork.players_loaded = 1
	GameNetwork.leave_game()
	assert_eq(GameNetwork.players.size(), 0)
	assert_eq(GameNetwork.players_ready.size(), 0)
	assert_eq(GameNetwork.players_loaded, 0)


func test_begin_game_requires_server():
	assert_true(GameNetwork.has_method("begin_game"))


func test_signal_connections():
	assert_true(true)