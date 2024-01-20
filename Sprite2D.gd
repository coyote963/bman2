extends Sprite2D

@export var input: PlayerInput;

func _process(delta):
	look_at(input.mouse_coordinates)
