##============================================================================##
#  BaseGameMode.gd — Abstract game mode controller                              #
#  Adapted from: Document "Structure de Base, Meta-Jeu"                       #
##============================================================================##

class_name BaseGameMode
extends Node

enum ModeType {
	CONTROL,
	ESCORT,
	NANO_GRAB,
}

enum WinCondition {
	TIME_LIMIT,
	OBJECTIVE_COMPLETE,
	TEAM_ELIMINATION,
	SCORE_LEAD,
}

@export var mode_type: ModeType
@export var win_condition: WinCondition = WinCondition.TIME_LIMIT
@export var match_duration: float = 180.0  # seconds (document: ~3 minutes)
@export var team_size: int = 4

var _match_started: bool = false
var _match_timer: float = 0.0
var _teams: Dictionary = {}  # team_id → score/stats
var _winning_team: int = -1

func start_match() -> void:
	_match_started = true
	_match_timer = match_duration
	EventBus.match_starting.emit()

func end_match(winner_team: int = -1) -> void:
	_match_started = false
	_winning_team = winner_team
	EventBus.match_ended.emit(winner_team)
	GameManager.instance.save_settings()

func _process(delta: float) -> void:
	if not _match_started:
		return
	_match_timer -= delta
	if _match_timer <= 0:
		_end_by_timeout()

func _end_by_timeout() -> void:
	_match_started = false
	var winner: int = _determine_winner()
	end_match(winner)

func _determine_winner() -> int:
	# Override in subclass
	return -1

func set_objective_progress(team_id: int, progress: float) -> void:
	if not _teams.has(team_id):
		_teams[team_id] = 0.0
	_teams[team_id] = progress
	if progress >= 1.0:
		end_match(team_id)

func record_kill(victim_team: int, killer_team: int) -> void:
	if not _teams.has(killer_team):
		_teams[killer_team] = 0
	_teams[killer_team] += 1

func get_team_score(team_id: int) -> int:
	return _teams.get(team_id, 0)

func get_remaining_time() -> float:
	return max(0.0, _match_timer)

func is_match_active() -> bool:
	return _match_started
