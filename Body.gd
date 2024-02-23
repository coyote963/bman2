extends Node2D

@export var input: PlayerInput
@onready var _animation_sprites = $PlayerAnimationSprites
@onready var _animation_player = $AnimationPlayer
@onready var _sprite = $Sprite2D

func _ready():
	NetworkTime.on_tick.connect(_tick)

func _tick(delta, tick):
	play_animation(get_parent().movement_state)

@rpc("any_peer", "call_local", "unreliable")
func play_animation(movement_state):
	var _is_facing_left = input.mouse_coordinates[0] < _animation_sprites.global_position.x
	var _is_moving_left = input.direction.x < 0
	_sprite.flip_h = _is_facing_left
	#Add flipping code here
	match movement_state:
		Globals.MovementState.IDLE:
			if input.down[1]:
				_animation_player.play("Crouch_Idle")
			else:
				_animation_player.play("Idle")				
		Globals.MovementState.JUMPING:
			if input.down[1]:
				_animation_player.play("Crouch_Jump")
			elif get_parent().velocity.y < 0:
				_animation_player.play("Jump_Up")
			else:
				_animation_player.play("Jump_Down")
		Globals.MovementState.RUNNING:
			if input.down[1]:
				if _is_facing_left != _is_moving_left:
					_animation_player.play_backwards("Crouch_Walk")
				else:
					_animation_player.play("Crouch_Walk")
			elif _is_facing_left != _is_moving_left:
				_animation_player.play_backwards("Running")
			else:
				_animation_player.play("Running")
		Globals.MovementState.ROLLING:
			if _is_facing_left != _is_moving_left:
				_animation_player.play("Back_Roll")
			else:
				_animation_player.play("Rolling")
		Globals.MovementState.CLIMBING:
			_animation_player.play("Climbing")
			if input.direction.y == 0:
				_animation_player.play("Hanging")
		Globals.MovementState.WALL_SLIDE:
			if input.down[1]:
				_animation_player.play("Wall_Crouch")
			else:
				_animation_player.play("Wall_Slide")

