##============================================================================##
#  hud.gd — In-game HUD (health, skill cooldowns, mini-map)                   #
#  Uses Kenney UI assets                                                       #
##============================================================================##

extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar/ProgressBar
@onready var health_text: Label = $HealthBar/Label
@onready var skill_1_slot: TextureRect = $SkillBar/Skill1/Icon
@onready var skill_1_cd: ProgressBar = $SkillBar/Skill1/Cooldown
@onready var skill_2_slot: TextureRect = $SkillBar/Skill2/Icon
@onready var skill_2_cd: ProgressBar = $SkillBar/Skill2/Cooldown
@onready var minimap: TextureRect = $MiniMap/TextureRect
@onready var score_label: Label = $ScoreLabel
@onready var timer_label: Label = $TimerLabel

var _hero: BaseHero = null
var _match_time: float = 0.0


func _ready() -> void:
	# Find local hero
	var heroes = get_tree().get_nodes_in_group("heroes")
	for h in heroes:
		if h is BaseHero and h.is_local_authority:
			_hero = h
			break
	if _hero:
		_hero.health_changed.connect(_on_health_changed)
		health_bar.max_value = _hero.max_health
		health_bar.value = _hero.max_health
		_on_health_changed(_hero.max_health, _hero.max_health, 0)


func _process(delta: float) -> void:
	_match_time += delta
	var minutes: int = int(_match_time / 60)
	var seconds: int = int(_match_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

	# Update skill cooldowns
	if _hero and _hero.combat_fsm:
		var skill = _hero.combat_fsm.current_skill
		if skill:
			var progress: float = skill._current_cooldown / skill.cooldown
			skill_1_cd.value = clamp(progress, 0.0, 1.0)


func _on_health_changed(old_hp: int, new_hp: int, overhealth: int) -> void:
	health_bar.value = new_hp
	health_text.text = "%d / %d" % [new_hp, _hero.max_health if _hero else 200]
	if overhealth > 0:
		health_bar.modulate = Color(0.0, 0.8, 1.0)  # Blue for overhealth
	else:
		health_bar.modulate = Color(1.0, 1.0, 1.0)


## Signal from EventBus
func _on_match_ended(winner_team: int) -> void:
	var msg: String = "VICTORY!" if (winner_team == (_hero.team_id if _hero else 0)) else "DEFEAT"
	score_label.text = msg
	score_label.visible = true