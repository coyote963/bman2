extends Control

func _on_host_pressed():
	Network.host_server()
	get_tree().change_scene_to_file("res://Scenes/NetworkedGame.tscn")

func _on_join_pressed():
	Network.join_server()
	get_tree().change_scene_to_file("res://Scenes/NetworkedGame.tscn")

func _on_ip_text_changed(new_text):
	Network.connect_ip = new_text

func _on_generate_pressed():
	Globals.player_name = Globals.namer.generate_name()
	$HBoxContainer/PlayerInfo/PlayerName.text = Globals.player_name

func _on_player_name_text_changed(new_text):
	Globals.player_name = new_text

func _on_rifle_pressed():
	pass # link to player getting rifle on spawn

func _on_pistol_pressed():
	pass # link to player getting pistol on spawn
