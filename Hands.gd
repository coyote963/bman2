extends Node2D

@export var input: PlayerInput;
@export var weapons: Array[Tool]

var ca = 0


func _ready():
	for weap in weapons:
		weap.input = input
		weap.hide()
		weap.enabled = false

func _on_player_switch_weapons():
	weapons[ca].hide()
	weapons[ca].enabled = false
	ca = (ca + 1) % weapons.size()
	weapons[ca].show()
	weapons[ca].update_hud()
	weapons[ca].enabled = true

func _process(delta):
	var mousepos = get_global_mouse_position()
	if !input.is_multiplayer_authority():
		look_at(input.mouse_coordinates)
	else:
		look_at(mousepos)
	scale.y = -1 if mousepos.x < global_position.x else 1


func _on_player_reload():
	weapons[ca]._reload_ammo()
	
