extends Control

var chatmessage = preload("res://Game/Misc/Chat/chat_message.tscn")
@onready var chatbox = $VBoxContainer/ScrollContainer/Chatbox
@onready var scrollbar = $VBoxContainer/ScrollContainer.get_v_scroll_bar()
@onready var input = $VBoxContainer/Input
var max_scroll_length = 0

func _ready():
	scrollbar.changed.connect(scrollbar_changed)
	max_scroll_length = scrollbar.max_value

func scrollbar_changed():
	if max_scroll_length != scrollbar.max_value:
		max_scroll_length = scrollbar.max_value
		$VBoxContainer/ScrollContainer.scroll_vertical = max_scroll_length

@rpc("any_peer", "reliable", "call_local") func chat_message(from_id, message):
	var m = chatmessage.instantiate()
	var p_name = Server.player_info[from_id][0]
	message = read_message_meta(message, m)
	m.text = "%s: %s" % [p_name, message]
	chatbox.add_child(m)

func _unhandled_key_input(event):
	if Input.is_action_pressed("Chat"):
		
		if input.text.length() > 0:
			input.select(0)
		input.grab_focus()

func _on_input_text_submitted(new_text):
	rpc("chat_message", Network.unique_id, new_text)
	input.text = ""
	input.release_focus()
	

func read_message_meta(message, message_node):
	
	var message_lower = message.to_lower()
	
	if message_lower.begins_with("m{"):
		
		var meta_begin = message.find("m{") + 2
		var meta_end = message.find("}") - 2
		var meta = message.substr(meta_begin, meta_end)
		var meta_array = meta.split(",")
		
		for pair in meta_array:
			
			var pair_array = pair.split("=")
			
			var key = pair_array[0]
			var value = ""
			
			if pair_array.size() != 1:
				value = pair_array[1]
			
			print("%s = %s" %[key, value])
			
			match key:
				
				"color": #takes value
					if value == "":
						return
					message_node.self_modulate = Color(value)
				
				"dork": #doesn't take value
					message = "Yo bro, you're a dork! Megadork!"
		
		message = message.trim_prefix("m{").trim_prefix(meta).trim_prefix("}")
	
	return message
