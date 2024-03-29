extends Node

var player = preload("res://player.tscn")

@export var connect_ip = "127.0.0.1"
@export var default_port = 55455
@export var players: Node

@onready var world = $World

@onready var spawnpoints = $Spawnpoints


var is_server = false
var is_client = false
var server = null
var client = null

var game = null
var default_pos = Vector2.ZERO
var tickrate = 0

func _ready():
	Network.game = self
	create_player(Network.unique_id, default_pos)

func handle_host():
	create_player(1, default_pos)

func _handle_connected(id: int):
	create_player(id, default_pos)

func _handle_new_peer(id: int):
	# create_player(id, default_pos)
	pass


func create_player(id, pos):
	print("%s: Created player %s" % [Network.unique_id, id])
	var p = player.instantiate()
	p.name = str(id)
	players.add_child(p)
	p.global_position = pos
	p.set_multiplayer_authority(1)
	if Server.player_info.has(id):
		p.get_node("Username").text = Server.player_info[id][0]
	# Avatar's input object is owned by player
	var input = p.find_child("PlayerInput")
	if input != null:
		input.set_multiplayer_authority(id)
		print("%s: Set %s's ownership to %s" % [multiplayer.get_unique_id(), p.name, id])

func remove_player(id):
	var p = players.get_node(str(id))
	p.queue_free()

func client_connected(id):
	print("%s connect to %s" % [multiplayer.get_unique_id(), id])
	create_player(id, default_pos)

func client_disconnected(id):
	#remove_player(id)
	pass
