extends CharacterBody2D

class_name PhysicalObject

@export var gravity = 980
@export var syncvelocity = Vector2()
@export var bounce : float = 0.5

func _ready():
	gravity = Globals.gravity
	$MultiplayerSynchronizer.replication_interval = NetworkTime.tickrate * 0.001 #For some reason, NetworkTime.tickrate is an integer. Here we're just converting it to milliseconds 
	$MultiplayerSynchronizer.delta_interval = NetworkTime.tickrate * 0.001
	#NetworkTime.on_tick.connect(_tick)

func _process(delta):
	
	velocity.y += gravity * delta
	
	velocity *= NetworkTime.physics_factor
	var collision_info = move_and_collide(velocity * delta)
	velocity /= NetworkTime.physics_factor
	
	if collision_info:
		velocity = velocity.bounce(collision_info.get_normal()) * bounce
	
	
	if Network.is_server:
		
		syncvelocity = velocity
	
	else:
		velocity = syncvelocity
