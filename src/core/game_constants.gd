##============================================================================##
#  GameConstants.gd — All numeric constants for Project Rush 2D                 #
##============================================================================##

class_name GameConstants
extends Node

## Network
const DEFAULT_PORT: int = 10567
const MAX_PLAYERS: int = 8
const TEAM_SIZE: int = 4
const PHYSICS_TICK_RATE: int = 60
const NETWORK_TICK_RATE: int = 60

## Combat
const BASE_MAX_HEALTH: int = 200
const BASE_ARMOR: int = 50
const OVERHEAL_MAX: int = 100
const STUN_DURATION: float = 0.8
const RECONCILIATION_THRESHOLD_PX: float = 2.0
const HIT_TOLERANCE_PX: float = 8.0
const LAG_COMPENSATION_MS: int = 500

## Movement
const BASE_MOVE_SPEED: float = 160.0
const MAX_MOVE_SPEED: float = 220.0
const INTERPOLATION_SPEED: float = 12.0

## Game Modes
const MATCH_DURATION: float = 180.0  # 3 minutes
const CONTROL_POINTS: int = 1
const ESCORT_DISTANCE: float = 2000.0
const NANO_GOAL: int = 100

## Monetization
const DAILY_AD_REWARD_NANOS: int = 25
const DAILY_AD_LIMIT: int = 3
const BATTLE_PASS_TIERS: int = 75
const BATTLE_PASS_FREE_WEEKLY: int = 3
const BATTLE_PASS_PREMIUM_WEEKLY: int = 5

## AI
const BOT_AVOIDANCE_RADIUS: float = 24.0
const BOT_PATH_RECALC_INTERVAL: float = 0.5
const BOT_HEALTH_FLEE_THRESHOLD: float = 0.2  # 20% health

## Input
const DRAG_TO_AIM_THRESHOLD: float = 0.1  # seconds before drag starts
const TARGET_LOCK_HOLD_TIME: float = 0.3  # seconds to lock
