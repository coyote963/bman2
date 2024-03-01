extends Node2D

@export var input: PlayerInput
@export var collision_checker: Area2D

const DroppedToolScene = preload("res://Game/Tools/Definitions/DroppedTool.tscn")

var _primary : Tool
var _secondary : Tool
var _overlapping_dropped_tool: DroppedTool
@onready var Pistol = preload("res://Game/Tools/Packed/Pistol.tscn")

func _ready():
	NetworkTime.on_tick.connect(_tick)
	_secondary = Pistol.instantiate()
	_primary = Pistol.instantiate()
	_primary.input = input
	#_primary.global_position = global_position
	add_child(_primary)
	$SecondarySprite.texture = _secondary.get_tool_texture()

func handle_switch():
	var temp = _primary
	_primary = _secondary
	_secondary = temp

func handle_throw():
	if _primary:
		var dropped = DroppedToolScene.instantiate()
		Network.game.world.add_child(dropped)

		dropped.velocity = Vector2(100, 100)

		dropped.position = global_position
		dropped.set_tool(_primary)
		_primary = null

func handle_pickup():
	var dt = collision_checker.get_overlapping_bodies().filter(func (x): return x.is_in_group("DroppedToolGroup"))
	if dt:
		handle_throw() 
		_primary = dt[0].tool
		dt[0].queue_free()
		_primary.play_idle()

func _process(delta):
	pass
	

func _tick(delta, tick):
	
	if input.switch[0]:
		handle_switch()
	elif input.throw[0]:
		handle_throw()
	elif input.interact[0]:
		handle_pickup()

