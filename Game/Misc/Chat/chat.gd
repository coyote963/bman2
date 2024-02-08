extends Control

var chatmessage = preload("res://Game/Misc/Chat/chat_message.tscn")
@onready var chatbox = $VBoxContainer/ScrollContainer/Chatbox
@onready var scrollbar = $VBoxContainer/ScrollContainer.get_v_scroll_bar()
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
	m.text = "%s: %s" % [p_name, message]
	chatbox.add_child(m)

func _unhandled_key_input(event):
	if event.is_action_pressed("Chat"):
		$VBoxContainer/Input.select(0)

func _on_input_text_submitted(new_text):
	rpc("chat_message", Network.unique_id, new_text)
	$VBoxContainer/Input.text = ""
