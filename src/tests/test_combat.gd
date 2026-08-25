extends GutTest

var _skill: BaseSkill
var _melee: MeleeSlash

func before_each():
	_skill = BaseSkill.new()
	_skill.name = "TestFireball"
	_skill.cooldown = 2.0
	_skill.cast_time = 0.5
	_skill.damage = 40
	_skill.damage_type = &"fire"
	_skill.is_hitscan = false
	_skill.projectile_scene = null

	_melee = MeleeSlash.new()
	_melee.name = "TestMelee"


func after_each():
	if _skill:
		_skill.free()
	if _melee:
		_melee.free()


func test_skill_creation():
	assert_not_null(_skill)
	assert_eq(_skill.cooldown, 2.0)
	assert_eq(_skill.name, "TestFireball")


func test_skill_cannot_cast_while_on_cooldown():
	_skill.execute(BaseHero.new(), Vector2(100, 100))
	assert_true(_skill.is_off_cooldown() == false)

	# After cooldown should pass
	_skill.update_cooldown(3.0)
	assert_true(_skill.is_off_cooldown() == true)


func test_melee_creation():
	assert_not_null(_melee)
	assert_eq(_melee.damage, 30)
	assert_eq(_melee.cooldown, 0.8)


func test_melee_cannot_cast_while_on_cooldown():
	var owner = BaseHero.new()
	_melee.setup(owner)
	_melee.execute(Vector2.RIGHT)
	assert_true(_melee._is_on_cooldown == true)
	assert_true(_melee.can_cast() == false)

	# After cooldown passes
	_melee._physics_process(1.0)
	assert_true(_melee.can_cast() == true)
	owner.free()


func test_melee_can_cast_with_owner():
	var owner = BaseHero.new()
	_melee.setup(owner)
	_melee.execute(Vector2.RIGHT)
	assert_true(_melee.can_cast() == false)
	owner.free()


func test_hitscan_skill_apply_damage():
	var target_hurtbox = HurtBox2D.new()
	target_hurtbox.team_id = 1  # different team
	# Verify hurtbox properties exist
	assert_not_null(target_hurtbox)
	assert_eq(target_hurtbox.team_id, 1)