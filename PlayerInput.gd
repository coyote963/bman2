extends Node
class_name PlayerInput

## Base class for Input nodes used with rollback.

var _is_prev_frame_jump = false
var is_jump_just_pressed = false
var is_jump_just_released = false
var horizontal_direction = 1
var is_holding_down = false
var mouse_coordinates = Vector2.ZERO

func _ready():
	NetworkTime.before_tick_loop.connect(_gather)

func get_horizontal_axis() -> float:
	return Input.get_axis("move_left", "move_right")

func _gather():
	if not is_multiplayer_authority():
		return
	is_jump_just_pressed = Input.is_action_pressed("jump") and not _is_prev_frame_jump
	is_jump_just_released = _is_prev_frame_jump and not Input.is_action_pressed("jump") 
	is_holding_down = Input.is_action_pressed("down")
	horizontal_direction = get_horizontal_axis()
	_is_prev_frame_jump = Input.is_action_pressed("jump")
	mouse_coordinates = owner.get_global_mouse_position()
