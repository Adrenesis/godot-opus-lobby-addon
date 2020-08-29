extends Control

var lobbyHolder : Control
var buttonShowServerSettings : Button
var buttonShowAdvancedPanelSettings : Button
var buttonShowDeviceSettings : Button
var buttonShowOverlay : Button
var buttonShowLogger : Button
var buttonServer : Control
var buttonClient : Control
var buttonStopServer : Button
var buttonStopClient : Button
var output : AudioStreamPlayer
var input : AudioStreamPlayer
var statusNode : Control
var buttonVoice : Control
var logger : Control
var overlay : Control
var advancedPanel : Control
var deviceSettings : Control
var nicknameField : LineEdit
var messageField : LineEdit
var portField : LineEdit
var ipField : LineEdit


func _ready():
	lobbyHolder = get_parent()
	output = lobbyHolder.get_node("Output")
	input = lobbyHolder.get_node("Input")
	
	var serverSettingsContainer = get_node("ServerSettingsContainer")
	statusNode = serverSettingsContainer.get_node("StatusContainer/Status")
	buttonVoice = serverSettingsContainer.get_node("ButtonVoice")
	buttonShowServerSettings = get_node("ShowServerSettings")
	buttonShowAdvancedPanelSettings = get_node("ShowAdvancedPanelSettings")
	buttonShowDeviceSettings = get_node("ShowDeviceSettings")
	buttonShowOverlay = get_node("ShowOverlay")
	buttonShowLogger = get_node("ShowLogger")
	portField = serverSettingsContainer.get_node('PortContainer/PortLineEdit')
	ipField = serverSettingsContainer.get_node('IPContainer/IPLineEdit')
	nicknameField = serverSettingsContainer.get_node('NicknameContainer/NicknameLineEdit')
	buttonServer = serverSettingsContainer.get_node("ServerButtonContainer/ButtonServer")
	buttonClient = serverSettingsContainer.get_node("ClientButtonContainer/ButtonClient")
	buttonStopServer = serverSettingsContainer.get_node("ServerButtonContainer/ButtonStopServer")
	buttonStopClient = serverSettingsContainer.get_node("ClientButtonContainer/ButtonStopClient")
	advancedPanel = get_node('EditorAudioBuses')
	deviceSettings = get_node('DeviceSettingsColorRect')
	overlay = get_node('EditorAudioBusesMini')
	logger = get_node("LoggerContainer/ScrollContainer/Log")
	messageField = get_node("LoggerContainer/MessageField")
	logger.text = get_parent().loggerLog
	logger.opusLobby = lobbyHolder
	lobbyHolder.displayer = self
	lobbyHolder.logger = logger
	lobbyHolder.statusNode = statusNode
	var error
	if not buttonShowServerSettings.is_connected("toggled", self, "_on_button_show_server_settings_toggled"):
		error = buttonShowServerSettings.connect("toggled", self, "_on_button_show_server_settings_toggled")
	if not buttonShowAdvancedPanelSettings.is_connected("toggled", self, "_on_button_show_advanced_panel_settings_toggled"):
		error = buttonShowAdvancedPanelSettings.connect("toggled", self, "_on_button_show_advanced_panel_settings_toggled")
	if not buttonShowDeviceSettings.is_connected("toggled", self, "_on_button_show_device_settings_toggled"):
		error = buttonShowDeviceSettings.connect("toggled", self, "_on_button_show_device_settings_toggled")
	if not buttonShowOverlay.is_connected("toggled", self, "_on_button_show_overlay_toggled"):
		error = buttonShowOverlay.connect("toggled", self, "_on_button_show_overlay_toggled")
	if not buttonShowLogger.is_connected("toggled", self, "_on_button_show_logger_toggled"):
		error = buttonShowLogger.connect("toggled", self, "_on_button_show_logger_toggled")
	if not buttonServer.is_connected("pressed", self, "_on_button_server_pressed"):
		error = buttonServer.connect("pressed", self, "_on_button_server_pressed")
	if not buttonClient.is_connected("pressed", self, "_on_button_client_pressed"):
		error = buttonClient.connect("pressed", self, "_on_button_client_pressed")
	if not buttonStopServer.is_connected("pressed", self, "_on_button_stop_server_pressed"):
		error = buttonStopServer.connect("pressed", self, "_on_button_stop_server_pressed")
	if not buttonStopClient.is_connected("pressed", self, "_on_button_stop_client_pressed"):
		error = buttonStopClient.connect("pressed", self, "_on_button_stop_client_pressed")
	if not buttonVoice.is_connected("button_down", self, "_on_button_voice_button_down"):
		error = buttonVoice.connect("button_down", self, "_on_button_voice_button_down")
	if not buttonVoice.is_connected("button_up", self, "_on_button_voice_button_up"):
		error = buttonVoice.connect("button_up", self, "_on_button_voice_button_up")
	if not output.is_connected("audio_buses_changed", advancedPanel, "read_audioserver_buses"):
		error = output.connect("audio_buses_changed", advancedPanel, "read_audioserver_buses")
	if not output.is_connected("audio_buses_changed", overlay, "read_audioserver_buses"):
		error = output.connect("audio_buses_changed", overlay, "read_audioserver_buses")
	if not Network.is_connected("client_started", lobbyHolder, "_on_client_started"):
		error = Network.connect("client_started", lobbyHolder, "_on_client_started")
	if not Network.is_connected("client_started", lobbyHolder, "_on_client_stopped"):
		error = Network.connect("client_started", lobbyHolder, "_on_client_stopped")
	if not Network.is_connected("connected_successfully", lobbyHolder, "_on_connected_successfully"):
		error = Network.connect("connected_successfully", lobbyHolder, "_on_connected_successfully")
	if not Network.is_connected("connection_failed", lobbyHolder, "_on_connection_failed"):
		error = Network.connect("connection_failed", lobbyHolder, "_on_connection_failed")
	if not Network.is_connected("server_disconnected", lobbyHolder, "_on_server_disconnected"):
		error = Network.connect("server_disconnected", lobbyHolder, "_on_server_disconnected")
	if not Network.is_connected("server_started", lobbyHolder, "_on_server_started"):
		error = Network.connect("server_started", lobbyHolder, "_on_server_started")
	if not Network.is_connected("server_stopped", lobbyHolder, "_on_server_stopped"):
		error = Network.connect("server_stopped", lobbyHolder, "_on_server_stopped")
	if not Network.is_connected("server_failed", lobbyHolder, "_on_server_failed"):
		error = Network.connect("server_failed", lobbyHolder, "_on_server_failed")
	if not Network.is_connected("player_connected", lobbyHolder, "_on_player_connected"):
		error = Network.connect("player_connected", lobbyHolder, "_on_player_connected")
	if not Network.is_connected("player_disconnected", lobbyHolder, "_on_player_disconnected"):
		error = Network.connect("player_disconnected", lobbyHolder, "_on_player_disconnected")
	if not Network.is_connected("client_failed", lobbyHolder, "_on_client_failed"):
		error = Network.connect("client_failed", lobbyHolder, "_on_client_failed")
	if not Network.is_connected("nickname_changed", lobbyHolder, "_on_nickname_changed"):
		error = Network.connect("nickname_changed", lobbyHolder, "_on_nickname_changed")
	if not Network.is_connected("players_name_updated", lobbyHolder, "_on_players_name_updated"):
		error = Network.connect("players_name_updated", lobbyHolder, "_on_players_name_updated")
	if not output.is_connected("packet_sent", lobbyHolder, "_on_packet_sent"):
		error = output.connect("packet_sent", lobbyHolder, "_on_packet_sent")
	if not output.is_connected("packet_received", lobbyHolder, "_on_packet_received"):
		error = output.connect("packet_received", lobbyHolder, "_on_packet_received")
	get_node("EditorAudioBuses").read_audioserver_buses(false)
	get_node("EditorAudioBusesMini").read_audioserver_buses(false)
	if lobbyHolder.status == lobbyHolder.STATUS_SERVER:
		disable_server_settings("server")
	elif lobbyHolder.status == lobbyHolder.STATUS_CLIENT:
		disable_server_settings("client")
	else:
		enable_server_settings()
	
func _queue_free():
	if Network.is_connected("audio_buses_changed", advancedPanel, "read_audioserver_buses"):
		Network.disconnect("audio_buses_changed", advancedPanel, "read_audioserver_buses")
	if Network.is_connected("audio_buses_changed", overlay, "read_audioserver_buses"):
		Network.disconnect("audio_buses_changed", overlay, "read_audioserver_buses")
	if Network.is_connected("client_started", lobbyHolder, "_on_client_started"):
		Network.disconnect("client_started", lobbyHolder, "_on_client_started")
	if Network.is_connected("client_stopped", lobbyHolder, "_on_client_stopped"):
		Network.disconnect("client_stopped", lobbyHolder, "_on_client_stopped")
	if Network.is_connected("connected_successfully", lobbyHolder, "_on_connected_successfully"):
		Network.disconnect("connected_successfully", lobbyHolder, "_on_connected_successfully")
	if Network.is_connected("connection_failed", lobbyHolder, "_on_connection_failed"):
		Network.disconnect("connection_failed", lobbyHolder, "_on_connection_failed")
	if Network.is_connected("server_disconnected", lobbyHolder, "_on_server_disconnected"):
		Network.disconnect("server_disconnected", lobbyHolder, "_on_server_disconnected")
	if Network.is_connected("server_started", lobbyHolder, "_on_server_started"):
		Network.disconnect("server_started", lobbyHolder, "_on_server_started")
	if Network.is_connected("server_stopped", lobbyHolder, "_on_server_stopped"):
		Network.disconnect("server_stopped", lobbyHolder, "_on_server_stopped")
	if Network.is_connected("server_failed", lobbyHolder, "_on_server_failed"):
		Network.disconnect("server_failed", lobbyHolder, "_on_server_failed")
	if Network.is_connected("player_connected", lobbyHolder, "_on_player_connected"):
		Network.disconnect("player_connected", lobbyHolder, "_on_player_connected")
	if Network.is_connected("player_disconnected", lobbyHolder, "_on_player_disconnected"):
		Network.disconnect("player_disconnected", lobbyHolder, "_on_player_disconnected")
	if Network.is_connected("client_failed", lobbyHolder, "_on_client_failed"):
		Network.disconnect("client_failed", lobbyHolder, "_on_client_failed")
	if Network.is_connected("nickname_changed", lobbyHolder, "_on_nickname_changed"):
		Network.disconnect("nickname_changed", lobbyHolder, "_on_nickname_changed")
	if Network.is_connected("players_name_updated", lobbyHolder, "_on_players_name_updated"):
		Network.disconnect("players_name_updated", lobbyHolder, "_on_players_name_updated")
	if output.is_connected("packet_sent", lobbyHolder, "_on_packet_sent"):
		output.disconnect("packet_sent", lobbyHolder, "_on_packet_sent")
	if output.is_connected("packet_received", lobbyHolder, "_on_packet_received"):
		output.disconnect("packet_received", lobbyHolder, "_on_packet_received")
	get_parent().displayer = null
	get_parent().logger = null
	get_parent().statusNode = null

func check_action_to_press_button(event : InputEvent, action : String, button : Button, keySum : int):
	if not InputMap.has_action(action):
		if event.get_scancode_with_modifiers() == keySum and event.pressed:
			button.pressed = not button.pressed
	else:
		if Input.is_action_just_pressed(action):
			button.pressed = not button.pressed

func escape_pressed():
	if get_focus_owner():
		if get_focus_owner() is LineEdit:
			get_focus_owner().deselect()
		get_focus_owner().release_focus()

func _unhandled_key_input(event):
	if get_parent().enable_hotkeys:
		check_action_to_press_button(
			event, "ui_opus_lobby_show_logger", 
			buttonShowLogger, KEY_Y)
		check_action_to_press_button(
			event, "ui_opus_lobby_show_overlay", 
			buttonShowOverlay, KEY_O)
		check_action_to_press_button(
			event, "ui_opus_lobby_show_advanced_panel_settings", 
			buttonShowAdvancedPanelSettings, KEY_MASK_SHIFT + KEY_O)
		check_action_to_press_button(
			event, "ui_opus_lobby_show_device_settings", 
			buttonShowDeviceSettings, KEY_MASK_SHIFT + KEY_U)
		check_action_to_press_button(
			event, "ui_opus_lobby_show_server_settings", 
			buttonShowServerSettings, KEY_U)
	if not InputMap.has_action("ui_opus_lobby_escape"):
		if event.get_scancode_with_modifiers() == KEY_ESCAPE and event.pressed:
			escape_pressed()
	elif Input.is_action_just_pressed("ui_opus_lobby_escape"):
		escape_pressed()
	if event.get_scancode_with_modifiers() == KEY_ENTER and event.pressed:
		if get_focus_owner() == null and buttonShowLogger.pressed:
			messageField.grab_focus()
	

func toggle_window(pressed : bool, player : AnimationPlayer):
	if pressed:
		player.play("show")
	else:
		player.play("hide")

func make_unfocusable_recursively(control : Control):
	if control.get("focus_mode") != null:
		control.focus_mode = Control.FOCUS_NONE
	for child in control.get_children():
		if child is Control:
			make_unfocusable_recursively(child)

func make_focusable_recursively(control : Control):
	if control is Button or control is LineEdit:
		control.set_focus_mode(Control.FOCUS_ALL)
	for child in control.get_children():
		if child is Control:
			make_focusable_recursively(child)

func _on_button_show_server_settings_toggled(pressed : bool):
	var player = buttonShowServerSettings.get_node("AnimationPlayer")
	toggle_window(pressed, player)
	if pressed:
		
		make_focusable_recursively(get_node("ServerSettingsColorRect"))
		make_focusable_recursively(get_node("ServerSettingsContainer"))
		nicknameField.grab_focus()
	else:
		make_unfocusable_recursively(get_node("ServerSettingsColorRect"))
		make_unfocusable_recursively(get_node("ServerSettingsContainer"))
		if self.is_a_parent_of(get_focus_owner()):
			get_focus_owner().release_focus()
			

func _on_button_show_device_settings_toggled(pressed : bool):
	deviceSettings.visible = pressed

func _on_button_show_advanced_panel_settings_toggled(pressed : bool):
	advancedPanel.visible = pressed
#	var player = buttonShowAdvancedPanelSettings.get_node("AnimationPlayer")
#	toggle_window(pressed, player)

func _on_button_show_overlay_toggled(pressed : bool):
	var player = buttonShowOverlay.get_node("AnimationPlayer")
	toggle_window(pressed, player)


func _on_button_show_logger_toggled(pressed : bool):
	var player = buttonShowLogger.get_node("AnimationPlayer")
	toggle_window(pressed, player)
	if pressed:
		make_focusable_recursively(get_node("LoggerContainer"))
		make_focusable_recursively(get_node("LoggerColorRect"))
		messageField.grab_focus()
		messageField.select()
		
	else:
		messageField.deselect()
		make_unfocusable_recursively(get_node("LoggerContainer"))
		make_unfocusable_recursively(get_node("LoggerColorRect"))
	

func disable_server_settings(type = "server"):
	portField.editable = false
	ipField.editable = false
	nicknameField.editable = false
	buttonServer.disabled = true
	buttonClient.disabled = true
	if type == "server":
		buttonStopServer.disabled = false
	else:
		buttonStopClient.disabled = false

func enable_server_settings(type = "server"):
	portField.editable = true
	ipField.editable = true
	nicknameField.editable = true
	buttonServer.disabled = false
	buttonClient.disabled = false
	if type == "server":
		buttonStopServer.disabled = true
	else:
		buttonStopClient.disabled = true

func _on_button_server_pressed() -> void:
	disable_server_settings()
	Network.serverPort = int(portField.text)
	Network.nickname = nicknameField.text
	Network.start_server()
	

func _on_button_client_pressed() -> void:
	disable_server_settings("client")
	Network.serverIp = ipField.text
	Network.serverPort = int(portField.text)
	Network.nickname = nicknameField.text
	Network.start_client()

func _on_button_stop_server_pressed() -> void:
	Network.remove_players()
	enable_server_settings()
	Network.stop_server()
	

func _on_button_stop_client_pressed() -> void:
	enable_server_settings("client")
	Network.remove_players()
	Network.stop_client()
	Network.remove_players()

func _on_button_voice_button_down() -> void:
	output.recording = true
	
func _on_button_voice_button_up() -> void:
	output.recording = false

