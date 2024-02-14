extends CharacterBody2D
@onready var _rightRaycast = $RightWalljumpRaycast
@onready var _leftRaycast = $LeftWalljumpRaycast
@onready var _animation_player = $AnimationPlayer
@onready var _animation_sprites = $PlayerAnimationSprites

@export var input: PlayerInput
@export var ladder_checker: Area2D

@export var air_friction = 200
@export var ground_friction = 1000
@export var gravity = 3000


var use_global_gravity = false

# Horizontal speed
@export var crouch_penalty = 0.2
@export var air_max_speed = 1200
@export var max_fall_speed = 1500
@export var air_acceleration = 150
@export var ground_max_speed = 1000
@export var ground_acceleration = 150

@export var double_jump_initial_speed = -1000
@export var jump_initial_speed = -1000
@export var fastfall_multiplier = 2
@export var jump_release_slowdown = 0.7

@export var walljump_initial_vertical_speed = -1400
@export var walljump_initial_horizontal_speed = -700
@export var wallslide_friction = 0.4

@export var ladder_dismount_velocity = Vector2(-700, -1000)
@export var climb_speed = 500
@export var crouch_walk_speed = 600
@export var roll_speed = 300
@export var roll_duration = 0.3

signal reload()
signal switch_weapons()

enum MovementState { RUNNING, IDLE, JUMPING, CROUCH_IDLE, CROUCH_WALK, CLIMBING, WALL_SLIDE, ROLLING }
var movement_state := MovementState.IDLE
var on_ladder := false
var has_double_jump = false
var roll_timer : SceneTreeTimer
var last_rolled := -1
var is_rolling = false
var _is_facing_left = false


func _ready():
	if use_global_gravity:
		gravity = Globals.gravity
	$IDLabel.text = name
	if input == null:
		input = $PlayerInput
	# Wait a single frame, so player spawner has time to set input owner
	await get_tree().process_frame
	$RollbackSynchronizer.process_settings()
	$RollingTimer.wait_time = roll_duration

func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity = Vector2.ZERO
	move_and_slide()
	velocity = old_velocity

func _on_rolling_timer_timeout():
	is_rolling = false

@rpc("any_peer", "call_local", "unreliable")
func play_animation():
	_is_facing_left = input.mouse_coordinates[0] < _animation_sprites.global_position.x
	var _is_moving_left = input.direction.x < 0
	_animation_sprites.flip_h = _is_facing_left
	match movement_state:
		MovementState.IDLE:
			_animation_player.play("Idle")
		MovementState.JUMPING:
			_animation_player.play("Jumping")
		MovementState.RUNNING:
			if _is_facing_left != _is_moving_left:
				_animation_player.play_backwards("Running")
			else:
				_animation_player.play("Running")
		MovementState.CROUCH_WALK:
			if _is_facing_left != _is_moving_left:
				_animation_player.play_backwards("Crouching")
			else:
				_animation_player.play("Crouching")
		MovementState.CROUCH_IDLE:
			_animation_player.play("Crouching")
		MovementState.ROLLING:
			_animation_player.play("Rolling")
		MovementState.CLIMBING:
			_animation_player.play("Climbing")
			if input.direction.y == 0:
				_animation_player.pause()

func clamp_to_ladder():
	var ladder_bodies = ladder_checker.get_overlapping_bodies().filter(func(x): return x.is_in_group("LadderGroup"))
	if ladder_bodies:
		var body = ladder_bodies[0]
		position.x = body.map_to_local(body.local_to_map(position)).x
	velocity = Vector2.ZERO

func _rollback_tick(delta, _tick, _is_fresh):
	_force_update_is_on_floor()
	if input.reload[0]:
		reload.emit()
	if input.switch[0]:
		switch_weapons.emit()
	print(input.interact)
	$State.text = MovementState.keys()[movement_state]
	match movement_state:
		MovementState.IDLE:
			if input.direction.x == 0 and is_on_floor():
				velocity.x = move_toward(velocity.x, 0, ground_friction)
			if input.direction.x != 0 and is_on_floor():
				velocity.x = move_toward(
					velocity.x,
					input.direction.x * ground_max_speed,
					ground_acceleration
				)
				movement_state = MovementState.RUNNING
			if not is_on_floor():
				movement_state = MovementState.JUMPING
			if input.jump[0]:
				velocity.y = jump_initial_speed
				movement_state = MovementState.JUMPING
			if input.down[1]:
				movement_state = MovementState.CROUCH_IDLE
		
		MovementState.RUNNING:
			if input.direction.x == 0 and is_on_floor():
				velocity.x = move_toward(velocity.x, 0, ground_friction)
				if velocity.x == 0:
					movement_state = MovementState.IDLE
			if input.direction.x != 0 and is_on_floor():
				velocity.x = move_toward(
					velocity.x,
					input.direction.x * ground_max_speed,
					ground_acceleration
				)
			if not is_on_floor():
				movement_state = MovementState.JUMPING
			if input.jump[0]:
				velocity.y = jump_initial_speed
				movement_state = MovementState.JUMPING
			if input.down[0]:
				velocity.x = roll_speed * (velocity.x / abs(velocity.x))
				last_rolled = NetworkTime.tick
				movement_state = MovementState.ROLLING
				is_rolling = true
				$RollingTimer.start()
				
				#get_tree().create_timer(roll_duration).timeout.connect(func():
					#movement_state = MovementState.IDLE
					#velocity = Vector2.ZERO
				#)
		
		MovementState.JUMPING:
			if input.down[1]:
				velocity.y += gravity * fastfall_multiplier * delta
			else:
				if velocity.y > max_fall_speed:
					velocity.y = max_fall_speed
				else:
					velocity.y += gravity * delta
			if input.direction.x != 0:
				velocity.x = move_toward(velocity.x, input.direction.x * air_max_speed, air_acceleration)
			else:
				velocity.x = move_toward(velocity.x, 0, air_friction)
			if _rightRaycast.is_colliding() or _leftRaycast.is_colliding():
				movement_state = MovementState.WALL_SLIDE
			if is_on_floor():
				has_double_jump = true
				movement_state = MovementState.IDLE
			if input.jump[2] and velocity.y < 0:
				velocity.y *= jump_release_slowdown
			if input.jump[0] and has_double_jump:
				has_double_jump = false
				velocity.y = double_jump_initial_speed
		
		MovementState.WALL_SLIDE:
			if input.down[1]:
				velocity.y += gravity * fastfall_multiplier * delta 
			elif velocity.y < 0:
				velocity.y += gravity * delta
			else:
				velocity.y = 200
			velocity.x = move_toward(velocity.x, input.direction.x * air_max_speed, air_acceleration)
			if not _rightRaycast.is_colliding() and not _leftRaycast.is_colliding():
				movement_state = MovementState.JUMPING
			if is_on_floor():
				movement_state = MovementState.IDLE
			if input.jump[0]:
				has_double_jump = true
				if _leftRaycast.is_colliding():
					velocity = Vector2(
						-1 * walljump_initial_horizontal_speed,
						walljump_initial_vertical_speed
					)
				else:
					velocity = Vector2(
						walljump_initial_horizontal_speed,
						walljump_initial_vertical_speed
					)
				movement_state = MovementState.JUMPING
				
		MovementState.CLIMBING:
			if input.interact[0]:
				velocity = Vector2(0, jump_initial_speed)
				movement_state = MovementState.JUMPING
			if input.direction.x != 0:
				velocity = Vector2(input.direction.x * -1 * ladder_dismount_velocity.x, ladder_dismount_velocity.y)
				movement_state = MovementState.JUMPING
			elif on_ladder:
				velocity.y = (
					int(input.down[1]) * climb_speed - 
					int(input.jump[1]) * climb_speed
				)
			else:
				velocity.y = 0
				movement_state = MovementState.JUMPING

		MovementState.CROUCH_IDLE:
			if input.direction.x != 0:
				movement_state = MovementState.CROUCH_WALK
			if not is_on_floor():
				movement_state = MovementState.JUMPING
			if not input.down[1]:
				movement_state = MovementState.IDLE
			
		MovementState.CROUCH_WALK:
			velocity.x = move_toward(
				velocity.x,
				input.direction.x * ground_max_speed * crouch_penalty,
				ground_acceleration
			)
			if not is_on_floor():
				movement_state = MovementState.JUMPING
			if not input.down[1] or input.down[2]:
				movement_state = MovementState.RUNNING
			if input.jump[0]:
				velocity.y = jump_initial_speed * delta
				movement_state = MovementState.JUMPING
			
		MovementState.ROLLING:
			if input.down[1]:
				velocity.y += gravity * fastfall_multiplier * delta
			else:
				velocity.y += gravity * delta
			if not is_rolling:
				movement_state = MovementState.IDLE
			if input.jump[0]:
				movement_state = MovementState.JUMPING
	
	if can_climb_ladder() and !movement_state == MovementState.CLIMBING:
		has_double_jump = true
		clamp_to_ladder()
		movement_state = MovementState.CLIMBING
	
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	play_animation.rpc()

func can_climb_ladder() -> bool:
	return on_ladder and input.interact[0]

func _on_ladder_checker_body_entered(_body):
	if _body.is_in_group("LadderGroup"):
		on_ladder = true

func _on_ladder_checker_body_exited(_body):
	if _body.is_in_group("LadderGroup"):
		if on_ladder:
			velocity.y = 0
			movement_state = MovementState.JUMPING
		on_ladder = false
