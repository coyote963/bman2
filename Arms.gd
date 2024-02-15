extends Node2D

class_name Arms

@onready var _arm_animations := $PrimaryAndArm/ArmAnimations as AnimationPlayer
@export var input: PlayerInput
@export var collision_checker: Area2D

const DroppedToolScene = preload("res://Game/Tools/Definitions/DroppedTool.tscn")

var _primary : Tool
var _secondary : Tool
var _overlapping_dropped_tool: DroppedTool

func _ready():
	NetworkTime.on_tick.connect(_tick)
	_secondary = load("res://Game/Tools/Packed/Pistol.tscn").instantiate()
	_primary = load("res://Game/Tools/Packed/Pistol.tscn").instantiate()


func reload():
	_arm_animations.play("Reload")

func handle_switch():
	var temp = _primary
	_primary = _secondary
	_secondary = temp
	_arm_animations.play("Switch")

func handle_throw():
	if _primary:
		var dropped = DroppedToolScene.instantiate()
		Network.game.world.add_child(dropped)

		dropped.velocity = Vector2(100*$PrimaryAndArm.scale.y,100)

		dropped.position = global_position
		dropped.set_tool(_primary)
		_primary = null

func handle_pickup():
	var dt = collision_checker.get_overlapping_bodies().filter(func (x): return x.is_in_group("DroppedToolGroup"))
	if dt:
		handle_throw() 
		_primary = dt[0].tool
		dt[0].queue_free()
		
func update_sprites():
	$SecondarySprite.texture = null if not _secondary else _secondary.get_tool_texture()
	$PrimaryAndArm/PrimarySprite.texture = null if not _primary else _primary.get_tool_texture() 

func _tick(delta, tick):
	if input.switch[0]:
		handle_switch()
	elif input.throw[0]:
		handle_throw()
	elif input.interact[0]:
		handle_pickup()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$PrimaryAndArm.look_at(get_global_mouse_position())

	if owner._is_facing_left:
		$PrimaryAndArm.scale.y = -1
	else:
		$PrimaryAndArm.scale.y = 1

	update_sprites()
