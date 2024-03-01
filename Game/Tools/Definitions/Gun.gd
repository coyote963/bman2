extends Tool

class_name Gun

@export var projectile: PackedScene
@export var weapon_stats: GunStats

enum GunState {
	IDLE,
	RELOADING,
	FIRING
}

var _gun_state := GunState.IDLE
var _last_fired := -1
func _ready():
	NetworkTime.on_tick.connect(_tick)


func can_fire():
	return (Time.get_ticks_msec() - _last_fired) / 1000.0 >= 1 / weapon_stats.fire_rate

func inputted_fire(input: PlayerInput):
	print(input.fire[0])
	return input.fire[0]

func _tick(delta, ticks):
	match _gun_state:
		GunState.IDLE:
			if inputted_fire(input) and can_fire():
				_last_fired = Time.get_ticks_msec()
				_gun_state = GunState.FIRING
			if input.reload[0]:
				_gun_state = GunState.RELOADING
		GunState.FIRING:
			if input.fire[2]:
				_gun_state = GunState.IDLE
			if tool_animation.get_curr_anim() == "IDLE":
				_gun_state = GunState.IDLE
			if input.reload[0]:
				_gun_state = GunState.RELOADING
		GunState.RELOADING:
			if tool_animation.get_curr_anim() == "IDLE":
				_gun_state = GunState.IDLE
	_play_animation()

func _play_animation():
	match _gun_state:
		GunState.IDLE:
			tool_animation.idle()
		GunState.RELOADING:
			tool_animation.reload()
		GunState.FIRING:
			tool_animation.fire()
	look_at(get_global_mouse_position())



