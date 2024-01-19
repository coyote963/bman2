extends Node

@export var connect_ip = "127.0.0.1"
@export var default_port = 55455

var unique_id = -1
var is_server = false
var is_client = false
var server = null
var client = null

var game = null

var tickrate = 0

func _ready():
	multiplayer.peer_connected.connect(client_connected)
	multiplayer.peer_disconnected.connect(client_disconnected)

func host_server():
	server = ENetMultiplayerPeer.new()
	server.create_server(default_port)
	multiplayer.multiplayer_peer = server
	unique_id = multiplayer.get_unique_id()
	is_server = true
	NetworkTime.start()


func join_server():
	client = ENetMultiplayerPeer.new()
	client.create_client(connect_ip, default_port)
	multiplayer.multiplayer_peer = client
	unique_id = multiplayer.get_unique_id()
	is_client = true
	NetworkTime.start()

	

func client_connected(id):
	game.create_player(id, game.default_pos)

func client_disconnected(id):
	game.remove_player(id)
