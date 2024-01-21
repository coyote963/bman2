extends CharacterBody2D
@onready var _rightRaycast = $RightWalljumpRaycast
@onready var _leftRaycast = $LeftWalljumpRaycast
@onready var _animated_sprite = $AnimatedSprite2D

@export var input: PlayerInput

@export var gravity = 980
@export var acceleration = 500
@export var max_speed = 1500
@export var friction = 500
@export var jump_initial_speed = -700
@export var walljump_initial_vertical_speed = -500
@export var walljump_initial_horizontal_speed = -200
@export var wallslide_acceleration = 0
@export var fastfall_acceleration = acceleration * 4
@export var jump_release_slowdown = 0.7

var direction
var has_double_jump = false

func _ready():
	
	gravity = Globals.gravity
	
	$IDLabel.text = name
	if input == null:
		input = $PlayerInput
	# Wait a single frame, so player spawner has time to set input owner
	await get_tree().process_frame
	$RollbackSynchronizer.process_settings()


func is_wall_sliding():
	
	return (
		(_rightRaycast.is_colliding() or _leftRaycast.is_colliding())
		and not is_on_floor()
		and velocity.y > 0
	)

func handle_wall_jump():
	
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
	
	if is_on_floor() and input.is_jump_just_pressed:
		velocity.y = jump_initial_speed
		has_double_jump = true
	if input.is_jump_just_released and velocity.y < 0:
		velocity.y *= jump_release_slowdown

func handle_double_jump():
	
	if not is_on_floor() and input.is_jump_just_pressed and has_double_jump:
		velocity.y = jump_initial_speed
		has_double_jump = false

func _rollback_tick(delta, tick, is_fresh):
	if is_wall_sliding() :
		velocity.y = 200
	else:
		velocity.y += gravity * delta
	
	direction = input.horizontal_direction
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	if is_wall_sliding():
		velocity.y = 200
	else:
		if Input.is_action_pressed("down"):
			velocity.y += fastfall_acceleration * delta
		else:
			velocity.y += gravity * delta
	handle_jump()
	handle_double_jump()
	handle_wall_jump()
	
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
