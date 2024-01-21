extends CharacterBody2D
@onready var _rightRaycast = $RightWalljumpRaycast
@onready var _leftRaycast = $LeftWalljumpRaycast
@onready var _animated_sprite = $AnimatedSprite2D

@export var input: PlayerInput

@export var air_friction = 1000
@export var ground_friction = 1000
@export var gravity = 980

# Horizontal speed
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

enum State { RUNNING, IDLE, JUMPING }
var animation_state = State.IDLE 

var direction
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

func apply_acceleration(direction):
	'''Apply acceleration in the direction, assumed to be a unit scalar'''
	_force_update_is_on_floor()
	if not is_on_floor():
		velocity.x = move_toward(velocity.x, direction * air_max_speed, air_acceleration)
	else:
		animation_state = State.RUNNING
		velocity.x = move_toward(velocity.x, direction * ground_max_speed, ground_acceleration)

func apply_friction():
	_force_update_is_on_floor()
	if not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, air_friction)
	else:
		animation_state = State.IDLE
		velocity.x = move_toward(velocity.x, 0, ground_friction)

func _process(_delta):
	if animation_state == State.IDLE:
		_animated_sprite.play("IDLE")
	elif animation_state == State.JUMPING:
		_animated_sprite.play("JUMPING")
	elif animation_state == State.RUNNING:
		_animated_sprite.play("RUNNING")
	_animated_sprite.set_flip_h(
		input.mouse_coordinates[0] < _animated_sprite.global_position.x
	)
	
	

func _rollback_tick(delta, tick, is_fresh):
	if is_wall_sliding() :
		velocity.y = 200
	else:
		if Input.is_action_pressed("down"):
			velocity.y += fastfall_multiplier * gravity * delta
		else:
			velocity.y += gravity * delta
	
	direction = input.horizontal_direction
	if direction != 0:
		apply_acceleration(direction)
	else:
		apply_friction()

	handle_jump()
	handle_double_jump()
	handle_wall_jump()
	
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
