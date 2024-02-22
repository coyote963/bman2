extends Node

@export var gravity = 980

var namer = NameGen.new()
var player_name = ""

enum MovementState { RUNNING, IDLE, JUMPING, CLIMBING, WALL_SLIDE, ROLLING}

var movement_state = MovementState.IDLE


func _ready():
	randomize()
	player_name = namer.generate_name()
	

func force_update_is_on_floor(object):
	var old_velocity = object.velocity
	object.velocity = Vector2.ZERO
	object.move_and_slide()
	object.velocity = old_velocity

