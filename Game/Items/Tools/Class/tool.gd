extends NetworkWeapon2D

class_name Tool


@export var fire_cooldown : float = 0.2 #time between shots
@export var projectile: PackedScene
@export var input: PlayerInput
@export var sound: AudioStreamPlayer2D
@export var projectile_speed : int = 800
@export var gravity : float = 980

enum firemodes {
	SEMI,
	AUTO,
	BURST
}

var last_fired: int = -1

func _is_reconcilable(p,rd,ld): #projectile, request data, local data
	return true

#func _reconcile(p,ld,rd): #projectile, local data, remote data
	#var local_transform = ld["global_transform"] as Transform2D
	##var remote_transform = rd["global_transform"] as Transform2D
##
	##var relative_transform = projectile.global_transform * local_transform.inverse()
	##var final_transform = remote_transform * relative_transform
#
	#p.global_transform = local_transform

func _ready():
	NetworkTime.on_tick.connect(_tick)

func _can_fire() -> bool:
	return NetworkTime.seconds_between(last_fired, NetworkTime.tick) >= fire_cooldown

# Needed to be publicly called
func after_fire(proj):
	_after_fire(proj)

func _after_fire(proj):
	last_fired = NetworkTime.tick
	#sound.play()

func _spawn() -> Node2D:
	print("pew")
	var p = projectile.instantiate()
	Network.game.world.add_child(p, true)
	p.fired_by = get_parent().get_parent()
	p.global_position = get_node("Muzzle").global_position
	p.velocity = Vector2(projectile_speed, 0).rotated(global_rotation) #set projectile velocity to projectile_speed rotated by the gun's rotation in radians
	p.speed = projectile_speed
	p.gravity = gravity
	return p

func _tick(delta, t):
	if input.is_firing:
		fire()
		

func _process(delta):
	#print(super._can_fire())
	pass
