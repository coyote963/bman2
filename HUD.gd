extends CanvasLayer
class_name HUD


@onready var ammo_label = %AmmoLabel
#
#func _ready():
	#_on_rifle_ammo_changed(0,0)

func _on_gun_ammo_changed(ammo, reserve):
	if ammo_label:
		ammo_label.text = str(ammo) + '/' + str(reserve)
