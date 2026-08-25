##============================================================================##
#  net/net_player.gd — Network-aware player wrapper                            #
#  Extends BaseHero with authority and RPC handling                            #
##============================================================================##

class_name NetPlayer
extends BaseHero

## Authority flag
var is_authority: bool = false:
	set(value):
		is_authority = value
		set_process_input(value)
		set_physics_process(value)

## Network references
@onready var net_player_id: int = multiplayer.get_unique_id()
@onready var owner_name: String = "local"

## RPC overrides - Authority matters
@rpc("call_local", "reliable")
func _on_local_authority_changed(new_auth: bool) -> void:
	is_authority = new_auth

@rpc("any_peer", "reliable")
func rpc_move(input: Vector2) -> void:
	# Clients send movement input; server validates via FSM
	if not is_authority:
		# Client-side prediction
		if movement_fsm:
			movement_fsm.set_input(input)

@rpc("call_local", "reliable")
func rpc_take_damage(amount: int, damage_type: StringName) -> void:
	if not is_alive:
		return
	var actual: int = health_component.take_damage(amount, damage_type, false)
	health_changed.emit(health_component.current_health, health_component.current_health, health_component.current_overhealth)
	if actual > 0 and is_dead():
		hero_died.emit(self)
		# Broadcast death
		rpc_die.rpc_reliable()

@rpc("call_local", "reliable")
func rpc_die() -> void:
	is_dead = true
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	modulate = Color(0.5, 0.5, 0.5, 0.7)

## Called by the game_network when spawning
func on_spawn(pos: Vector2) -> void:
	global_position = pos
	is_authority = multiplayer.is_server()
	if is_authority:
		# Server controls this hero
		set_process_input(true)
		set_physics_process(true)
	else:
		# Client: input will be RPC'd from server/authority
		set_process_input(false)
		set_physics_process(false)

## Called every physics tick when we have authority
func _physics_process(delta: float) -> void:
	if not is_local_authority or is_dead:
		return

	# Simple input reading (client or server depending on authority)
	var input_dir: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	if movement_fsm and movement_fsm.is_stunned():
		velocity = velocity.move_toward(Vector2.ZERO, 14.0 * delta)
		move_and_slide()
		return

	if input_dir.length() > 0.01:
		# Convert to isometric
		var iso_dir: Vector2 = Vector2(input_dir.x, input_dir.y * 0.5)
		if iso_dir.length() > 1.0:
			iso_dir = iso_dir.normalized()
		if movement_fsm:
			movement_fsm.set_input(iso_dir)
		var target_velocity: Vector2 = iso_dir * 160.0
		velocity = velocity.move_toward(target_velocity, 12.0 * 160.0 * delta)
		velocity_direction = iso_dir
		facing_direction = iso_dir
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 14.0 * delta)
		velocity_direction = Vector2.ZERO

	if velocity.length() > 220.0:
		velocity = velocity.normalized() * 220.0

	move_and_slide()


func _process(delta: float) -> void:
	if velocity_direction.length() > 0.01:
		facing_direction = velocity_direction