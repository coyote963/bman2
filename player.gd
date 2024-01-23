extends CharacterBody2D
@onready var _rightRaycast = $RightWalljumpRaycast
@onready var _leftRaycast = $LeftWalljumpRaycast
@onready var _animated_sprite = $PlayerAnimation

@export var input: PlayerInput

@export var air_friction = 200
@export var ground_friction = 1000
@export var gravity = 980

# Horizontal speed
@export var crouch_penalty = 0.5
@export var air_max_speed = 800
@export var air_acceleration = 80
@export var ground_max_speed = 800
@export var ground_acceleration = 150

@export var jump_initial_speed = -1000
@export var fastfall_multiplier = 3
@export var jump_release_slowdown = 0.7

@export var walljump_initial_vertical_speed = -700
@export var walljump_initial_horizontal_speed = -500
@export var wallslide_speed = 200

@export var ladder_dismount_velocity = Vector2(-1000, -1000)
@export var climb_speed = 500

enum State { RUNNING, IDLE, JUMPING, CROUCH_IDLE, CROUCH_WALK, CLIMBING }
var animation_state := State.IDLE
var direction
var on_ladder := false
var has_double_jump = false

func _ready():
	$IDLabel.text = name
	if input == null:
		input = $PlayerInput
	# Wait a single frame, so player spawner has time to set input owner
	await get_tree().process_frame
	$RollbackSynchronizer.process_settings()

func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity = Vector2.ZERO
	move_and_slide()
	velocity = old_velocity

func is_wall_sliding():
	_force_update_is_on_floor()
	return (
		(_rightRaycast.is_colliding() or _leftRaycast.is_colliding())
		and not is_on_floor()
		and velocity.y > 0
	)

func handle_wall_jump():
	_force_update_is_on_floor()
	if (
		(_rightRaycast.is_colliding() or _leftRaycast.is_colliding()) and
		input.is_jump_just_pressed and
		not is_on_floor() 
	):
		velocity.y = walljump_initial_vertical_speed
		if _leftRaycast.is_colliding():
			velocity.x = -1 * walljump_initial_horizontal_speed
		else:
			velocity.x = walljump_initial_horizontal_speed
		has_double_jump = true

func handle_jump():
	_force_update_is_on_floor()
	if is_on_floor() and input.is_jump_just_pressed:
		animation_state = State.JUMPING
		velocity.y = jump_initial_speed
		has_double_jump = true
	if input.is_jump_just_released and velocity.y < 0:
		velocity.y *= jump_release_slowdown

func handle_double_jump():
	_force_update_is_on_floor()
	if not is_on_floor() and input.is_jump_just_pressed and has_double_jump:
		animation_state = State.JUMPING
		velocity.y = jump_initial_speed
		has_double_jump = false

func apply_acceleration():
	'''Apply acceleration in the direction, assumed to be a unit scalar'''
	_force_update_is_on_floor()
	if not is_on_floor():
		velocity.x = move_toward(velocity.x, direction * air_max_speed, air_acceleration)
	else:
		if input.is_holding_down:
			animation_state = State.CROUCH_WALK
			velocity.x = move_toward(
				velocity.x,
				direction * ground_max_speed * crouch_penalty,
				ground_acceleration
			)
		else:
			animation_state = State.RUNNING
			velocity.x = move_toward(
				velocity.x,
				direction * ground_max_speed,
				ground_acceleration
			)

func apply_friction():
	_force_update_is_on_floor()
	if not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, air_friction)
	else:
		animation_state = State.CROUCH_IDLE if input.is_holding_down else State.IDLE
		velocity.x = move_toward(velocity.x, 0, ground_friction)


@rpc("any_peer", "call_local", "unreliable")
func play_animation():
	var _is_flipped = input.mouse_coordinates[0] < _animated_sprite.global_position.x
	_animated_sprite.set_flip_h(_is_flipped)
	if animation_state == State.IDLE:
		_animated_sprite.play("IDLE")
	elif animation_state == State.JUMPING:
		_animated_sprite.play("JUMPING")
	elif animation_state == State.RUNNING:
		_animated_sprite.play("RUNNING")
	elif animation_state == State.CROUCH_WALK:
		_animated_sprite.play("CROUCH_WALK")
	elif animation_state == State.CROUCH_IDLE:
		_animated_sprite.play("CROUCH_IDLE")

func _rollback_tick(delta, _tick, _is_fresh):
	if animation_state != State.CLIMBING:
		if is_wall_sliding() :
			velocity.y = wallslide_speed
		else:
			if Input.is_action_pressed("down"):
				velocity.y += fastfall_multiplier * gravity * delta
			else:
				velocity.y += gravity * delta
		
		direction = input.horizontal_direction
		if direction != 0:
			apply_acceleration()
		else:
			apply_friction()

		handle_jump()
		handle_double_jump()
		handle_wall_jump()
		
		
		
		if velocity.x != 0:
			animation_state = State.RUNNING
			
		if can_climb_ladder():
			animation_state = State.CLIMBING
		
	else:
		velocity.x = 0
		velocity.y = 0
		if input.horizontal_direction != 0:
			animation_state = State.RUNNING
			has_double_jump = true
			velocity = Vector2(
				-1 * ladder_dismount_velocity.x * input.horizontal_direction, 
				ladder_dismount_velocity.y
			)
		if input.is_holding_down:
			velocity.y =  climb_speed
		if input.is_holding_up:
			velocity.y = -1 * climb_speed
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	play_animation.rpc()

func can_climb_ladder() -> bool:
	return on_ladder and Input.is_action_pressed("interact")

func _on_ladder_checker_body_entered(body):
	print(body)
	on_ladder = true


func _on_ladder_checker_body_exited(body):
	on_ladder = false
