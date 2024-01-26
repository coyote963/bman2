extends RayCast2D

@export var speed : int = 500
@export var gravity_affect : float = 0.25
@export var gravity : int = 980
@export var lifetime : int = 10
@export var use_global_gravity : bool = true

var fired_by = null

var velocity = Vector2()

func _ready():
	if use_global_gravity:
		gravity = Globals.gravity
	
	$Timer.wait_time = lifetime
	$Timer.start()

func _process(delta):
	
	if is_colliding():
		print("collision at " + str(get_collision_point()))
		global_position = get_collision_point()
		velocity = Vector2.ZERO
		queue_free()
	
	var old_position = global_position #record position from last frame
	
	velocity.y += gravity * gravity_affect * delta
	global_position += velocity * delta #move the projectile
	
	var posdiff = velocity * delta
	
	target_position = posdiff #cast the ray from our current position to our last position in local space
	
	force_raycast_update() #now rerun collision checking 
	
	if is_colliding():
		global_position = get_collision_point()
		velocity = Vector2.ZERO
		queue_free()
	
	$DebugTracer.add_point(global_position)

func _on_timer_timeout():
	queue_free()

func _on_hitbox_body_entered(body):
	queue_free()
