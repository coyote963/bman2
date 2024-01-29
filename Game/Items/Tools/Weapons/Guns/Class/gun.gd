extends Tool

class_name Gun

@onready var _hud := %HUD

@export var mag_size : int = 12
@export var reserve : int = 48

var enabled := false
var ammo

func _ready():
	super._ready()
	ammo = mag_size


func _can_fire():
	if ammo <= 0 or not enabled:
		return false
	return super._can_fire() #check if cooldown is done

func update_hud():
	_hud._on_gun_ammo_changed(ammo, reserve)

func _after_fire(proj):
	ammo -= 1
	update_hud()
	super._after_fire(proj)

func _reload_ammo():
	var needed_bullets = mag_size - ammo
	if needed_bullets <= reserve:
		reserve -= needed_bullets
		ammo = mag_size
	else:
		reserve = 0
		ammo += reserve
	update_hud()
