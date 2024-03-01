extends Node2D

class_name Tool
@export var tool_animation: ToolAnimation
@export var input: PlayerInput

func get_tool_texture():
	return tool_animation.get_weapon_sprite()

