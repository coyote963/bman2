extends RayCast2D

@export var speed : int = 500
@export var gravity_affect : float = 0.25
@export var gravity : int = 980
@export var use_global_gravity : bool = true

var fired_by = null

var velocity = Vector2()

func _ready():
	if use_global_gravity:
		gravity = Globals.gravity

func _process(delta):
	var old_position = global_position #record position from last frame
	
	velocity.y += gravity * gravity_affect
	global_position += velocity * delta #move the projectile
	
	target_position = old_position - global_position #cast the ray from our current position to our last position in local space
	
	force_raycast_update() #now rerun collision checking 
	
	if is_colliding():
		print("collision at " + str(get_collision_point()))
