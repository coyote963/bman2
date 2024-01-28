extends Node

@export var gravity = 980

var SETTINGS = {
	
}

func force_update_is_on_floor(object):
	var old_velocity = object.velocity
	object.velocity = Vector2.ZERO
	object.move_and_slide()
	object.velocity = old_velocity
