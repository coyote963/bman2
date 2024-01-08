extends Node

var player = preload("res://player.tscn")

@onready var world = $World
@onready var players = $Players
@onready var spawnpoints = $Spawnpoints

var default_pos = Vector2.ZERO

func _ready():
	
	default_pos = spawnpoints.get_child(0).global_position
	
	Network.game = self
	
	#if Network.is_server:
		#
		#Server.game = self
		#
	#elif Network.is_client:
		#
		#Client.game = self
	
	create_player(Network.unique_id, default_pos) #create a player for ourselves

func create_player(id, pos):
	
	var p = player.instantiate()
	p.name = str(id)
	
	players.add_child(p)
	
	p.global_position = pos
	
	p.set_multiplayer_authority(id)

func remove_player(id):
	var p = find_player(id)
	p.queue_free()

func find_player(id):
	return players.get_node(str(id))
