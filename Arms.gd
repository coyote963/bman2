extends Node2D

class_name Arms

@onready var _arm_animations := $PrimaryAndArm/ArmAnimations as AnimationPlayer
@export var input: PlayerInput
var _p
var _s
var _is_holding_primary := true

func _ready():
	Signals.update_gun_sprites.connect(_handle_sprites_update)

func _update_sprites(sprite_node: Sprite2D, t: Tool):
	if t:
		sprite_node.texture = t.get_tool_texture()
	else:
		sprite_node.texture = null

func _handle_sprites_update(p: Tool, s: Tool):
	_update_sprites($PrimaryAndArm/PrimarySprite, p)
	_update_sprites($SecondarySprite, s)
	$Sprite2D.texture = null if not p else p.get_tool_texture()

func reload():
	# Play the reload animation
	if _is_holding_primary:
		_arm_animations.play("Reload")
	else:
		_arm_animations.play_backwards("Reload")
	_is_holding_primary = not _is_holding_primary



func set_sprite(primary_texture, secondary_texture):
	$WeaponSprite.set_texture(primary_texture)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$PrimaryAndArm.look_at(get_global_mouse_position())
