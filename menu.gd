extends Control

func _on_host_pressed():
	Network.host_server()
	get_tree().change_scene_to_file("res://Scenes/NetworkedGame.tscn")

func _on_join_pressed():
	Network.join_server()
	get_tree().change_scene_to_file("res://Scenes/NetworkedGame.tscn")

func _on_ip_text_changed(new_text):
	Network.connect_ip = new_text
