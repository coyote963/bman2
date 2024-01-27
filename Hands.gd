extends Node2D

@export var input: PlayerInput;

func _process(delta):
	var mousepos = get_global_mouse_position()
	if !input.is_multiplayer_authority():
		look_at(input.mouse_coordinates)
	else:
		look_at(mousepos)
	
	if mousepos.x < global_position.x:
		scale.y = -1
	else:
		scale.y = 1
