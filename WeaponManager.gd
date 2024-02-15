extends Node2D

class_name WeaponManager
# Class that handles switching weapons, picking up weapons, dropping weapons


const DroppedToolScene = preload("res://Game/Tools/Definitions/DroppedTool.tscn")
@export var input: PlayerInput
var primary: PackedScene
var secondary: PackedScene
@export var arms: Arms
var p
var s

func _ready():
	# Placeholder for when we make an actual weapon selector
	s = load("res://Game/Tools/Packed/Pistol.tscn").instantiate()
	p = load("res://Game/Tools/Packed/Pistol.tscn").instantiate()
	NetworkTime.on_tick.connect(_tick)
	#update_weapon_sprites()

func switch_weapons():
	var temp = p
	p = s
	s = temp
	#update_weapon_sprites()

func throw_weapon():
	if p:
		var dropped = DroppedToolScene.instantiate()
		Network.game.world.add_child(dropped)
		dropped.velocity = Vector2(100,100)
		dropped.position = global_position
		dropped.set_tool(p)
		p = null
	#update_weapon_sprites()


func _tick(delta, tick):
	if input:
		if input.switch[0]:
			switch_weapons()
			arms.switch()
		elif input.throw[0]:
			arms.throw()
			throw_weapon()

