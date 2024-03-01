extends Node2D

class_name ToolAnimation

@export var tool_animation_player: AnimationPlayer
@export var weapon_sprite: Texture2D

func on_anim_finished(animation_name):
	if animation_name != "IDLE":
		idle()

func _ready():
	tool_animation_player.animation_finished.connect(on_anim_finished)

func reload():
	tool_animation_player.play("RELOADING")
	
func fire():
	tool_animation_player.play("FIRING")

func idle():
	tool_animation_player.play("IDLE")

func get_curr_anim():
	return tool_animation_player.current_animation

func get_weapon_sprite():
	return weapon_sprite
