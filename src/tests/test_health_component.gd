##============================================================================##
#  test_health_component.gd — GUT test for HealthComponent                    #
##============================================================================##

extends GutTest

var health_comp: HealthComponent

func before_each():
	health_comp = HealthComponent.new()
	add_child(health_comp)

func after_each():
	health_comp.queue_free()

func test_initial_health():
	health_comp.max_health = 200
	health_comp._ready()
	assert_eq(health_comp.current_health, 200, "Should start at max health")
	assert_true(health_comp.is_alive, "Should be alive")
	assert_eq(health_comp.get_health_percent(), 1.0, "Should be at 100%")

func test_take_damage_basic():
	health_comp.max_health = 200
	health_comp._ready()
	var damage = health_comp.take_damage(50, &"bullet")
	# armor=50 → damage = max(1, 50-50) = max(1, 0) = 1
	assert_eq(damage, 1, "Should take 1 damage after armor")
	assert_eq(health_comp.current_health, 199, "Should have 199 health after 1 actual damage")

func test_take_damage_no_armor():
	health_comp.max_health = 200
	health_comp.armor = 0
	health_comp._ready()
	var damage = health_comp.take_damage(50, &"bullet")
	assert_eq(damage, 50, "Should take 50 damage with no armor")
	assert_eq(health_comp.current_health, 150, "Should have 150 health")

func test_critical_bypasses_armor():
	health_comp.max_health = 200
	health_comp.armor = 100
	health_comp._ready()
	var damage = health_comp.take_damage(50, &"melee", true)  # critical=true
	assert_eq(damage, 50, "Critical should bypass armor")
	assert_eq(health_comp.current_health, 150, "Should have 150 health")

func test_overhealth_absorbs_damage():
	health_comp.max_health = 200
	health_comp._ready()
	health_comp.apply_overhealth(50)
	var damage = health_comp.take_damage(100, &"bullet")
	# armor=50 → overhealth=50 absorbs 50, remaining 50 damage → max(1, 50-50) = 1
	assert_eq(damage, 1, "Overhealth absorbed 50, armor reduces remaining 50 to 1")
	assert_eq(health_comp.current_health, 199, "Should have 199 health after 1 damage")

func test_death():
	health_comp.max_health = 10
	health_comp._ready()
	var died_called = false
	health_comp.connect("died", self._on_died)
	health_comp.take_damage(999, &"bullet")
	assert_true(not health_comp.is_alive, "Should be dead")

func _on_died(_hero):
	assert_true(true, "died signal emitted")

func test_heal():
	health_comp.max_health = 200
	health_comp.current_health = 50
	health_comp._ready()
	var healed = health_comp.heal(100)
	assert_eq(healed, 100, "Should heal 100")
	assert_eq(health_comp.current_health, 150, "Should have 150 health")

func test_heal_overflow():
	health_comp.max_health = 200
	health_comp.current_health = 190
	health_comp._ready()
	var healed = health_comp.heal(100)
	assert_eq(healed, 10, "Should heal only to max (200-190=10)")
	assert_eq(health_comp.current_health, 200, "Should be capped at max")
