extends Label

var messageField : LineEdit
var opusLobby : Control

func _ready():
	messageField = get_node("../../MessageField")
	messageField.connect("gui_input", self, "_on_field_input")

func _on_field_input(ev : InputEvent):
	if ev is InputEventKey:
		if ev.get_scancode() == KEY_ENTER and ev.pressed:
			if messageField.text != '':
				send_message()
#				messageField.release_focus()
			else:
				messageField.release_focus()

remote func receive_message(_id, nickname, message):
	opusLobby.send_to_logger("%s: %s" % [nickname, message])

func send_message():
	var nickname = Network.nickname
	var message = messageField.text
	opusLobby.send_to_logger("%s: %s" % [nickname, message])
	messageField.text = ''
	rpc("receive_message", get_tree().get_network_unique_id(), nickname, message)

