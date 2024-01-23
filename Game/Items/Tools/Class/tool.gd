extends NetworkWeapon2D

class_name Tool

@export var fire_cooldown : float = 0.2 #time between shots
@export var projectile: PackedScene
@export var input: PlayerInput
@export var sound: AudioStreamPlayer2D

enum firemodes {
	SEMI,
	AUTO,
	BURST
}

var last_fired: int = -1

func _ready():
	NetworkTime.on_tick.connect(_tick)
	
func _can_fire() -> bool:
	return NetworkTime.seconds_between(last_fired, NetworkTime.tick) >= fire_cooldown

func _after_fire(proj):
	last_fired = NetworkTime.tick
	sound.play()

func _spawn():
	if !projectile == null:
		var p = projectile.instantiate()
		Network.game.world.add_child(p)
		p.fired_by = get_parent().get_parent()
		
		return p

func _tick(delta, t):
	if input.is_firing:
		#fire()
		pass
