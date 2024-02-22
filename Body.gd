extends Node2D

@export var input: PlayerInput
@onready var _animation_sprites = $PlayerAnimationSprites
@onready var _animation_player = $AnimationPlayer

func _ready():
	NetworkTime.on_tick.connect(_tick)

func _tick(delta, tick):
	play_animation(get_parent().movement_state)

@rpc("any_peer", "call_local", "unreliable")
func play_animation(movement_state):
	var _is_facing_left = input.mouse_coordinates[0] < _animation_sprites.global_position.x
	var _is_moving_left = input.direction.x < 0
	_animation_sprites.flip_h = _is_facing_left
	match movement_state:
		Globals.MovementState.IDLE:
			_animation_player.play("Idle")
		Globals.MovementState.JUMPING:
			_animation_player.play("Jumping")
		Globals.MovementState.RUNNING:
			if _is_facing_left != _is_moving_left:
				_animation_player.play_backwards("Running")
			else:
				_animation_player.play("Running")
		Globals.MovementState.ROLLING:
			_animation_player.play("Rolling")
		Globals.MovementState.CLIMBING:
			_animation_player.play("Climbing")
			if input.direction.y == 0:
				_animation_player.pause()

