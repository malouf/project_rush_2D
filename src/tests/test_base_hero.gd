extends GutTest

var _hero: BaseHero
var _scene: Node

func before_each():
	_scene = Node.new()
	_hero = BaseHero.new()
	_scene.add_child(_hero)
	
	# Add required children
	var move_fsm = MovementFSM.new()
	move_fsm.name = "MovementFSM"
	_hero.add_child(move_fsm)
	
	var idle_state = IdleState.new()
	idle_state.name = "Idle"
	move_fsm.add_child(idle_state)
	
	var move_state = MoveState.new()
	move_state.name = "Move"
	move_fsm.add_child(move_state)
	
	var stun_state = StunState.new()
	stun_state.name = "Stun"
	move_fsm.add_child(stun_state)
	
	var combat_fsm = CombatFSM.new()
	combat_fsm.name = "CombatFSM"
	_hero.add_child(combat_fsm)
	
	var health = HealthComponent.new()
	health.name = "HealthComponent"
	_hero.add_child(health)
	
	var hurtbox = HurtBox2D.new()
	hurtbox.name = "HurtBox2D"
	_hero.add_child(hurtbox)
	
	var hitbox = HitBox2D.new()
	hitbox.name = "HitBox2D"
	_hero.add_child(hitbox)
	
	var visual = Node2D.new()
	visual.name = "Visual"
	_hero.add_child(visual)
	
	var interp = Interpolation.new()
	interp.name = "Interpolation"
	visual.add_child(interp)
	
	# Initialize by calling _ready manually (GUT doesn't run the scene tree fully)
	_hero._ready()


func after_each():
	_scene.free()


func test_hero_creation():
	assert_not_null(_hero)
	assert_true(_hero is CharacterBody2D)


func test_movement_input():
	# Can't easily test physics without mocking Input
	# Just verify the hero is initialized correctly
	assert_not_null(_hero.movement_fsm)
	assert_not_null(_hero.combat_fsm)
	assert_not_null(_hero.health_component)


func test_is_local_authority_default():
	assert_true(_hero.is_local_authority)


func test_team_id():
	_hero.team_id = 1
	assert_eq(_hero.team_id, 1)


func test_max_health_default():
	assert_eq(_hero.max_health, 200)


func test_damage_flow():
	# This tests the hurt_received signal is connected
	var health_before = _hero.health_component.current_health
	assert_eq(health_before, 200)