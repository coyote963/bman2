extends AnimatedSprite2D

@onready var _sprite = $"."

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_multiplayer_authority():
		if event.position[0] - get_viewport().size[0] / 2 < 0:
			_sprite.set_flip_h(true)
		else:
			_sprite.set_flip_h(false)
