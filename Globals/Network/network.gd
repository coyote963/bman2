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
	
	Server.player_info[unique_id] = [Globals.player_name]

func join_server():
	client = ENetMultiplayerPeer.new()
	client.create_client(connect_ip, default_port)
	multiplayer.multiplayer_peer = client
	unique_id = multiplayer.get_unique_id()
	is_client = true
	NetworkTime.start()

func client_connected(id):
	game.create_player(id, game.default_pos)
	if is_server:
		Server.player_info[str(id)] = "Unconnected"
		rpc_id(id, "request_client_info")

func client_disconnected(id):
	game.remove_player(id)

@rpc("reliable") func request_client_info(): #Clientside. server asked us for our name
	if is_client:
		rpc_id(1, "send_client_info", [Globals.player_name], unique_id)

@rpc("reliable", "any_peer") func send_client_info(p_info, new_p_id): #Shared. get the new client's info. #p_info is an array containing all necessary information
	if is_server:
		Server.player_info[str(new_p_id)] = p_info
		print("server: " + str(Server.player_info))
		#forward the new client's necessary info to the other clients on the server
		var ids = multiplayer.get_peers()
		for c in ids:
			if c != unique_id: #but make sure it's not executed on the severside
				rpc_id(c, "send_client_info", p_info, new_p_id)
	
	if is_client:
		Server.player_info[str(new_p_id)] = p_info
		print("client: " + str(Server.player_info))
