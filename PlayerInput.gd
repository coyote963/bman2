extends Node
class_name PlayerInput

## Base class for Input nodes used with rollback.
@export var queue_size : int

var direction = Vector2.ZERO
var down := [false, false, false ]
var jump := [false, false, false ]
var interact := [false, false, false ]
var mouse_coordinates = Vector2.ZERO

class InputBuffer:
	# Add base class for movement keys
	var _queues = {}
	var _ptr = 0
	var _queue_size : int
	var _action_names := []
	
	func _init(queue_size, action_names):
		self._action_names = action_names
		for an in action_names:
			self._queue_size = queue_size
			self._queues[an] = []
			self._queues[an].resize(queue_size)
			self._queues[an].fill(false)
	
	func update_tick():
		self._ptr = (self._ptr + 1) % self._queue_size
		for an in self._action_names:
			self._queues[an][self._ptr] = Input.is_action_pressed(an)
	
	func get_state(an):
		# Returns [just_pressed, is_pressed, just_released]
		return [
			self._queues[an][self._ptr] and not self._queues[an][self._ptr - 1 % self._queue_size],
			self._queues[an][self._ptr],
			not self._queues[an][self._ptr] and self._queues[an][self._ptr - 1 % self._queue_size]
		]

func _ready():
	NetworkTime.before_tick_loop.connect(_gather)

func get_axis() -> Vector2:
	return Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("down", "jump")
	)

var input_buffer = InputBuffer.new(10, [
	"down",
	"jump",
	"interact"
])

func _gather():
	if not is_multiplayer_authority():
		return
	input_buffer.update_tick()
	direction = get_axis()
	down = input_buffer.get_state("down")
	jump = input_buffer.get_state("jump")
	interact = input_buffer.get_state("interact")
	mouse_coordinates = owner.get_global_mouse_position()
