extends CharacterBody2D
@onready var _rightRaycast = $RightWalljumpRaycast
@onready var _leftRaycast = $LeftWalljumpRaycast
@onready var _animated_sprite = $PlayerAnimation

@export var input: PlayerInput
@export var ladder_checker: Area2D

@export var air_friction = 200
@export var ground_friction = 1000
@export var gravity = 980

# Horizontal speed
@export var crouch_penalty = 0.5
@export var air_max_speed = 800
@export var air_acceleration = 80
@export var ground_max_speed = 800
@export var ground_acceleration = 150

@export var double_jump_initial_speed = -600
@export var jump_initial_speed = -700
@export var fastfall_multiplier = 3
@export var jump_release_slowdown = 0.7

@export var walljump_initial_vertical_speed = -700
@export var walljump_initial_horizontal_speed = -500
@export var wallslide_friction = 0.4

@export var ladder_dismount_velocity = Vector2(-500, -600)
@export var climb_speed = 500

enum MovementState { RUNNING, IDLE, JUMPING, CROUCH_IDLE, CROUCH_WALK, CLIMBING, WALL_SLIDE }
var movement_state := MovementState.IDLE
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

@rpc("any_peer", "call_local", "unreliable")
func play_animation():
	var _is_flipped = input.mouse_coordinates[0] < _animated_sprite.global_position.x
	_animated_sprite.set_flip_h(_is_flipped)
	if movement_state == MovementState.IDLE:
		_animated_sprite.play("IDLE")
	elif movement_state == MovementState.JUMPING:
		_animated_sprite.play("JUMPING")
	elif movement_state == MovementState.RUNNING:
		_animated_sprite.play("RUNNING")
	elif movement_state == MovementState.CROUCH_WALK:
		_animated_sprite.play("CROUCH_WALK")
	elif movement_state == MovementState.CROUCH_IDLE:
		_animated_sprite.play("CROUCH_IDLE")

func clamp_to_ladder():
	var bodies = ladder_checker.get_overlapping_bodies()
	if bodies:
		var body = bodies[0]
		position.x = body.map_to_local(body.local_to_map(position)).x
	velocity = Vector2.ZERO

func _rollback_tick(delta, _tick, _is_fresh):
	direction = input.direction.x
	_force_update_is_on_floor()
	match movement_state:
		MovementState.IDLE:
			if direction == 0 and is_on_floor():
				velocity.x = move_toward(velocity.x, 0, ground_friction)
			if direction != 0 and is_on_floor():
				velocity.x = move_toward(
					velocity.x,
					direction * ground_max_speed,
					ground_acceleration
				)
				movement_state = MovementState.RUNNING
			if not is_on_floor():
				movement_state = MovementState.JUMPING
			if input.jump[0]:
				velocity.y = jump_initial_speed
				movement_state = MovementState.JUMPING
			if can_climb_ladder():
				clamp_to_ladder()
				movement_state = MovementState.CLIMBING
			if input.down[1]:
				movement_state = MovementState.CROUCH_IDLE
		
		MovementState.RUNNING:
			if direction == 0 and is_on_floor():
				velocity.x = move_toward(velocity.x, 0, ground_friction)
				if velocity.x == 0:
					movement_state = MovementState.IDLE
			if direction != 0 and is_on_floor():
				velocity.x = move_toward(
					velocity.x,
					direction * ground_max_speed,
					ground_acceleration
				)
			if not is_on_floor():
				movement_state = MovementState.JUMPING
			if input.jump[0]:
				velocity.y = jump_initial_speed
				movement_state = MovementState.JUMPING
			if can_climb_ladder():
				clamp_to_ladder()
				movement_state = MovementState.CLIMBING
			if input.down[1]:
				movement_state = MovementState.CROUCH_IDLE
		
		MovementState.JUMPING:
			if input.down[1]:
				velocity.y += gravity * fastfall_multiplier * delta
			else:
				velocity.y += gravity * delta
			if direction != 0:
				velocity.x = move_toward(velocity.x, direction * air_max_speed, air_acceleration)
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
				velocity.y += gravity * wallslide_friction * fastfall_multiplier * delta 
			else:
				velocity.y += gravity * wallslide_friction * delta
			velocity.x = move_toward(velocity.x, direction * air_max_speed, air_acceleration)
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
			
			if direction != 0:
				velocity = Vector2(direction * -1 * ladder_dismount_velocity.x, ladder_dismount_velocity.y)
				movement_state = MovementState.JUMPING
			else:
				velocity.y = (
					int(input.down[1]) * climb_speed - 
					int(input.jump[1]) * climb_speed
				)

		MovementState.CROUCH_IDLE:
			if direction != 0:
				movement_state = MovementState.CROUCH_WALK
			if input.jump[0]:
				velocity.y = jump_initial_speed * delta
				movement_state = MovementState.JUMPING
			if can_climb_ladder():
				clamp_to_ladder()
				movement_state = MovementState.CLIMBING
		# Crouch Walk
		# This is when the player is walking while crouching
		MovementState.CROUCH_WALK:
			if direction != 0:
				velocity.x = move_toward(
					velocity.x,
					direction * ground_max_speed * crouch_penalty,
					ground_acceleration
				)
			if not input.down[1]:
				movement_state = MovementState.RUNNING
			if can_climb_ladder():
				clamp_to_ladder()
				movement_state = MovementState.CLIMBING
			if input.jump[0]:
				velocity.y = jump_initial_speed * delta
				movement_state = MovementState.JUMPING

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
