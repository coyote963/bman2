extends CharacterBody2D
@onready var _rightRaycast = $RightWalljumpRaycast
@onready var _leftRaycast = $LeftWalljumpRaycast
@onready var _animated_sprite = $PlayerAnimation

@export var input: PlayerInput
@export var ladder_checker: Area2D

@export var air_friction = 200
@export var ground_friction = 1000
@export var gravity = 5000

# Horizontal speed
@export var crouch_penalty = 0.5
@export var air_max_speed = 600
@export var max_fall_speed = 1500
@export var air_acceleration = 250
@export var ground_max_speed = 500
@export var ground_acceleration = 150

@export var double_jump_initial_speed = -1200
@export var jump_initial_speed = -1200
@export var fastfall_multiplier = 1.3
@export var jump_release_slowdown = 0.7

@export var walljump_initial_vertical_speed = -1400
@export var walljump_initial_horizontal_speed = -700
@export var wallslide_friction = 0.4

@export var ladder_dismount_velocity = Vector2(-1000, -1000)
@export var climb_speed = 500
@export var crouch_walk_speed = 600
@export var roll_speed = 300
@export var roll_duration = 2.0

enum MovementState { RUNNING, IDLE, JUMPING, CLIMBING, HANGING, WALL_SLIDE, ROLLING }
var movement_state := MovementState.IDLE
var on_ladder := false
var has_double_jump = false
var roll_timer : SceneTreeTimer
var last_rolled := -1.0

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

func _on_rolling_timer_timeout() -> void:
	print("timerou!")
	movement_state = MovementState.IDLE

func _create_rolling_timer(duration):
	var timer = get_tree().create_timer(duration)
	#timer.connect("timeout", timer, "_on_rolling_timer_timeout")
	#timer.start()

@rpc("any_peer", "call_local", "unreliable")
func play_animation():
	var _is_facing_left = input.mouse_coordinates[0] < _animated_sprite.global_position.x
	var _is_moving_left = input.direction.x < 0
	_animated_sprite.set_flip_h(_is_facing_left)
	if movement_state == MovementState.IDLE:
		if input.down[1]:
			_animated_sprite.play("CROUCH_IDLE")
		else:
			_animated_sprite.play("IDLE")
	elif movement_state == MovementState.JUMPING:
		if input.down[1]:
				_animated_sprite.play("CROUCH_JUMP")
		else:
			if velocity.y > 0:
				_animated_sprite.play("JUMPING_DOWN")
			else:
				_animated_sprite.play("JUMPING_UP")
	elif movement_state == MovementState.RUNNING:
		if input.down[1]:
			if _is_facing_left != _is_moving_left:
				_animated_sprite.play_backwards("CROUCH_WALK")
			else:
				_animated_sprite.play("CROUCH_WALK")
		else:
			if _is_facing_left != _is_moving_left:
				_animated_sprite.play_backwards("RUNNING")
			else:
				_animated_sprite.play("RUNNING")
	elif movement_state == MovementState.ROLLING:
		if _is_facing_left != _is_moving_left:
			_animated_sprite.play("BACK_ROLL")
		else:
			_animated_sprite.play("ROLLING")
	elif movement_state == MovementState.CLIMBING:
		_animated_sprite.play("CLIMBING")
	elif movement_state == MovementState.WALL_SLIDE:
		_animated_sprite.play("WALL_SLIDE")
	elif movement_state == MovementState.HANGING:
		_animated_sprite.play("HANGING")

func clamp_to_ladder():
	var bodies = ladder_checker.get_overlapping_bodies()
	if bodies:
		var body = bodies[0]
		position.x = body.map_to_local(body.local_to_map(position)).x
	velocity = Vector2.ZERO

func _rollback_tick(delta, _tick, _is_fresh):
	_force_update_is_on_floor()
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
				var direction_to_cursor = (input.mouse_coordinates - _animated_sprite.global_position).normalized()
				var is_moving_towards_cursor = input.direction.x * direction_to_cursor.x > 0
				movement_state = MovementState.RUNNING
			if not is_on_floor():
				movement_state = MovementState.JUMPING
			if input.jump[0]:
				velocity.y = jump_initial_speed
				movement_state = MovementState.JUMPING
			if can_climb_ladder():
				clamp_to_ladder()
				movement_state = MovementState.CLIMBING
				
		MovementState.RUNNING:
			if input.direction.x == 0 and is_on_floor():
				velocity.x = move_toward(velocity.x, 0, ground_friction)
				if velocity.x == 0:
					movement_state = MovementState.IDLE
			if input.direction.x != 0 and is_on_floor():
				if input.down[1]:
					velocity.x = move_toward(velocity.x, input.direction.x * ground_max_speed * crouch_penalty, ground_acceleration)
				else:
					velocity.x = move_toward(velocity.x, input.direction.x * ground_max_speed, ground_acceleration)
			if not is_on_floor():
				movement_state = MovementState.JUMPING
			if input.jump[0]:
				velocity.y = jump_initial_speed
				movement_state = MovementState.JUMPING
			if can_climb_ladder():
				clamp_to_ladder()
				movement_state = MovementState.CLIMBING
			if input.down[0]:
				velocity.x = roll_speed * velocity.x / abs(velocity.x)
				movement_state = MovementState.ROLLING
				last_rolled = NetworkTime.tick
				
				#get_tree().create_timer(roll_duration).timeout.connect(func():
					#movement_state = MovementState.IDLE
					#velocity = Vector2.ZERO
				#)
		
		MovementState.JUMPING:
			if input.down[1]:
				if velocity.y > 0:
					velocity.y += gravity * fastfall_multiplier * delta
				else:
					velocity.y += gravity * delta
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
			if can_climb_ladder():
				has_double_jump = true
				clamp_to_ladder()
				movement_state = MovementState.CLIMBING
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
			if can_climb_ladder():
				clamp_to_ladder()
				movement_state = MovementState.CLIMBING
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
				velocity.y = jump_initial_speed
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
				velocity.y = jump_initial_speed
				#movement_state = MovementState.JUMPING
			has_double_jump = true
			if velocity.y == 0:
				movement_state = MovementState.HANGING
		
		MovementState.HANGING:
			if input.interact[0]:
				velocity.y = jump_initial_speed
				movement_state = MovementState.JUMPING
			if input.direction.x != 0:
				velocity = Vector2(input.direction.x * -1 * ladder_dismount_velocity.x, ladder_dismount_velocity.y)
				movement_state = MovementState.JUMPING
			elif on_ladder:
				velocity.y = (
					int(input.down[1]) * climb_speed - 
					int(input.jump[1]) * climb_speed
				)
				if velocity.y != 0:
					movement_state = MovementState.CLIMBING
			else:
				velocity.y = jump_initial_speed
			has_double_jump = true
			
		MovementState.ROLLING:
			print((NetworkTime.tick - last_rolled) / NetworkTime.tickrate)
			if input.down[1]:
				velocity.y += gravity * fastfall_multiplier * delta
			else:
				velocity.y += gravity * delta
			if input.jump[0]:
				movement_state = MovementState.JUMPING
			if can_climb_ladder():
				clamp_to_ladder()
				movement_state = MovementState.CLIMBING
			if (NetworkTime.tick - last_rolled) / NetworkTime.tickrate > roll_duration:
				movement_state = MovementState.IDLE
				
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	play_animation.rpc()

func can_climb_ladder() -> bool:
	return on_ladder and input.interact[0]

func _on_ladder_checker_body_entered(body):
	on_ladder = true

func _on_ladder_checker_body_exited(body):
	on_ladder = false
