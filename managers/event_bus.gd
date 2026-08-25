##============================================================================##
#  EventBus.gd — Global signal dispatcher for Project Rush 2D                #
#  Adapts from: Document spec "EventBus global"                               #
##============================================================================##

extends Node

# Meta-game signals
signal settings_changed
signal game_started
signal game_ended

# Player signals
signal player_damaged(hero: Node, damage: int, is_critical: bool)
signal player_died(hero: Node)
signal player_respawned(hero: Node, team_id: int)

# Combat signals
signal ability_used(caster: Node, skill_name: String, target: Variant)
signal ability_cooldown_updated(skill_name: String, remaining: float)
signal nano_collected(amount: int)

# Game feel signals
signal screen_shake_requested(intensity: Vector2, duration: float, falloff: int)
signal hit_stop_requested(duration_ms: float)

# Game mode signals
signal objective_captured(point_id: int)
signal match_starting
signal match_ended(winner_team: int)

# UI signals
signal ui_screen_requested(screen_name: String, data: Dictionary)
signal target_locked(hero: Node)
signal social_auth_complete(player_id: String, display_name: String, token: String)
