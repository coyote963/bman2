extends Control

var chatmessage = preload("res://Game/Misc/Chat/chat_message.tscn")
@onready var chatbox = $VBoxContainer/ScrollContainer/Chatbox
@onready var scrollbar = $VBoxContainer/ScrollContainer.get_v_scroll_bar()
@onready var input = $VBoxContainer/Input
var max_scroll_length = 0

var chatlog = []

var fade = false

func _ready():
	scrollbar.changed.connect(scrollbar_changed)
	max_scroll_length = scrollbar.max_value
	chat_message(0, "{color=aaaaaa}Welcome. Hit T to chat.")

func scrollbar_changed():
	if max_scroll_length != scrollbar.max_value:
		max_scroll_length = scrollbar.max_value
		$VBoxContainer/ScrollContainer.scroll_vertical = max_scroll_length

@rpc("any_peer", "reliable", "call_local") func chat_message(from_id, message):
	var m = chatmessage.instantiate()
	
	chatlog.append(message)
	
	message = read_message_meta(message, m)
	
	m.text = message
	
	var p_name = ""
	if from_id != 0:
		p_name = Server.player_info[from_id][0]
		m.text = "%s: %s" % [p_name, message]
	
	chatbox.add_child(m)
	
	fade = false
	modulate.a = 1
	$FadeTimer.start()

func _unhandled_key_input(event):
	if Input.is_action_pressed("Chat"):
		
		if !input.has_focus():
			
			if input.text.length() > 0:
				input.select(0)
			input.grab_focus()
			
			
		if input.has_focus():
			fade = false
			modulate.a = 1

func _on_input_text_submitted(new_text):
	rpc("chat_message", Network.unique_id, new_text)
	input.text = ""
	input.release_focus()

func read_message_meta(message, message_node):
	
	var message_lower = message.to_lower()
	
	if message_lower.begins_with("{"):
		
		var meta_begin = message.find("{") + 1
		var meta_end = message.find("}") - 1
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
		
		message = message.trim_prefix("{").trim_prefix(meta).trim_prefix("}")
	
	return message

func _process(delta):
	if modulate.a > 0 and fade:
		modulate.a = move_toward(modulate.a, 0, delta)

func _on_fade_timer_timeout():
	fade = true
