extends Node2D

@export var input: PlayerInput;

func _process(delta):
	if !input.is_multiplayer_authority():
		look_at(input.mouse_coordinates)
	else:
		look_at(get_global_mouse_position())
