extends Node
class_name PlayerInput

## Base class for Input nodes used with rollback.
var is_jump_just_pressed = false
var is_jump_just_released = false
var horizontal_direction = 1
var is_holding_down = false

func _ready():
	NetworkTime.before_tick_loop.connect(_gather)

func get_horizontal_axis() -> float:
	return Input.get_axis("move_left", "move_right")

func _gather():
	if not is_multiplayer_authority():
		print("%s Tried to control %s" % [owner.name, multiplayer.get_unique_id()])
		return
	is_jump_just_pressed = Input.is_action_just_pressed("jump")
	is_jump_just_released = Input.is_action_just_released("jump")
	is_holding_down = Input.is_action_pressed("down")
	horizontal_direction = get_horizontal_axis()
