extends Node
const OpusLobbyDisplayer = preload("res://addons/adrenesis.opusLobby/scenes/OpusLobbyDisplayer.tscn")
export (bool) var enable_hotkeys
var remove_display : bool = false
var display_removed : bool = false
var loggerLog : String = ""
var logger : Control = null
var statusNode : Control = null
var displayer : Control = null
var statusString : String
var status : int = STATUS_DISCONNECTED

enum {
	STATUS_SERVER,
	STATUS_CLIENT,
	STATUS_DISCONNECTED
}

func get_time_string():
	var timeDict = OS.get_time()
	var hour = timeDict.hour
	var minute = timeDict.minute
	var second = timeDict.second
	return "[%02d:%02d:%02d] " % [hour, minute, second]

func _process(delta):
	if remove_display and not display_removed:
		remove_child(displayer)
		display_removed = true
	if not remove_display and display_removed:
		add_child(OpusLobbyDisplayer.instance())
		display_removed = false

func _input(event):
	if event is InputEventKey:
		if not InputMap.has_action("ui_opus_lobby_push_to_talk"):
			if event.get_scancode_with_modifiers() == KEY_V:
				if event.pressed:
					$Output.recording = true
				else:
					$Output.recording = false
		else:
			if Input.is_action_just_pressed("ui_opus_lobby_push_to_talk"):
				if event.pressed:
					$Output.recording = true
				else:
					$Output.recording = false

func send_to_logger(message):
	if logger:
		logger.text += get_time_string() + message + "\n"
	loggerLog += message + "\n"

func update_status(message):
	if statusNode:
		statusNode.text = message
		statusString = message

func _on_client_started():
	update_status("Connecting...")
	send_to_logger("Trying to connect...")
	status = STATUS_DISCONNECTED
	

func _on_client_stopped():
	update_status("Not Started.")
	send_to_logger("Disconnected.")
	status = STATUS_DISCONNECTED
	displayer.buttonVoice.disabled = true

func _on_connected_successfully():
	send_to_logger("Connected.")
	update_status("Connected OK!")
	status = STATUS_CLIENT
	displayer.buttonVoice.disabled = false

func _on_connection_failed():
	send_to_logger("Failed to connect.")
	update_status("Error.")
	status = STATUS_DISCONNECTED
	if displayer:
		displayer.enable_server_settings("client")

func _on_server_disconnected():
	send_to_logger("Server disconnected.")
	update_status("Disconnected")
	status = STATUS_DISCONNECTED
	if displayer:
		displayer.enable_server_settings("client")

func _on_server_failed():
	send_to_logger("Failed to create server!")
	update_status("Error.")
	status = STATUS_DISCONNECTED
	if displayer:
		displayer.enable_server_settings()

func _on_server_started():
	send_to_logger("Server Successfully started!")
	update_status("Server started!")
	status = STATUS_SERVER
	if displayer:
		displayer.buttonVoice.disabled = false

func _on_server_stopped():
	send_to_logger("Server stopped... Every peer has been disconnected.")
	update_status("Not Started.")
	status = STATUS_DISCONNECTED
	if displayer:
		displayer.buttonVoice.disabled = true

func _on_player_connected(id, nickname):
	send_to_logger("Player %s with id %s connected" % [ nickname, id ])

func _on_player_disconnected(id, nickname):
	send_to_logger("Player %s with id %s disconnected" % [ nickname, id ])

func _on_client_failed():
	update_status("Error.")
	send_to_logger("Failed to create client!")
	status = STATUS_DISCONNECTED
	if displayer:
		displayer.enable_server_settings()

func _on_nickname_changed(nickname):
	if displayer:
		displayer.nicknameField.text = nickname

func _on_players_name_updated():
	if displayer:
		print("names_updating")
		displayer.overlay.read_audioserver_buses(true)
		displayer.advancedPanel.read_audioserver_buses(true)

func _on_packet_sent(size):
	# End up memory leaking for now because of labels' drawcalls
#	send_to_logger("send recording of size %s" % size)
	pass

func _on_packet_received(id):
	# End up memory leaking for now
#	send_to_logger("received audio from player with id: %s" % id)
	pass
