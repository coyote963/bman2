extends Tool

class_name Gun

@export var mag_size : int = 12
@export var reserve : int = 48

var ammo = 0

func _ready():
	super._ready()
	ammo = mag_size

func _can_fire():
	if ammo <= 0:
		return false
	return super._can_fire() #check if cooldown is done
