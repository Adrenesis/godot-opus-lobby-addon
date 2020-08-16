extends Control
var busId = -1

var inputNode
var soloButton
var muteButton
var bypassButton
var volumeSlider = null
var volumeLabel = null
var volumePanel = null
var volumePanelTimer = null
var leftDisplay = null
var rightDisplay = null
var effectTree


func _ready():
	volumeSlider = find_node("VolumeSlider")
	volumeSlider.connect('value_changed', self, 'update_volume')
	volumeSlider.connect('gui_input', self, 'volume_slider_input')
	volumeLabel = find_node("VolumeLabel")
	volumeSlider.hint_tooltip = str(volumeSlider.value) + " dB"
	volumeLabel.text = "     " + str(volumeSlider.value) + " dB"
	volumePanel = find_node("VolumePanel")
	volumePanelTimer = volumePanel.get_node('Timer')
	volumePanelTimer.connect("timeout", volumePanel, "set_visible", [ false ])
	soloButton = find_node("SoloButton")
	muteButton = find_node("MuteButton")
	bypassButton = find_node("BypassButton")
	if AudioServer.is_bus_solo(busId):
		soloButton.modulate = 'ffad00'
		soloButton.pressed = true
	else:
		soloButton.modulate = 'ffffff'
	if AudioServer.is_bus_mute(busId):
		muteButton.modulate = 'de2424'
		muteButton.pressed = true
	else:
		muteButton.modulate = 'ffffff'
	if bypassButton:
		if AudioServer.is_bus_bypassing_effects(busId):
			bypassButton.modulate = '1db3e0'
			bypassButton.pressed = true
		else:
			bypassButton.modulate = 'ffffff'
		bypassButton.connect("toggled", self, "switch_bypass_toggle")
	soloButton.connect("toggled", self, "switch_solo_toggle")
	muteButton.connect("toggled", self, "switch_mute_toggle")
	effectTree = find_node("EffectTree")
	if effectTree:
		var treeRoot = effectTree.create_item()
		for i in range(0, AudioServer.get_bus_effect_count(busId)):
			var effectItem = effectTree.create_item(treeRoot)
			var effectString = str(AudioServer.get_bus_effect_instance(busId, i))
			effectString = effectString.replace('AudioEffect', '')
			effectString = effectString.replace('Instance', '')
			effectItem.set_text(0, effectString)
			effectItem = effectTree.create_item(treeRoot)
	var outputOptionButton = find_node("OutputOptionButton")
	if outputOptionButton:
		outputOptionButton.text = AudioServer.get_bus_send(busId)

func _process(delta):
	if not leftDisplay:
		leftDisplay = find_node("TextureProgress")
	if not rightDisplay:
		rightDisplay = find_node("TextureProgress2")
	leftDisplay.value = AudioServer.get_bus_peak_volume_left_db(busId, 0) 
	rightDisplay.value = AudioServer.get_bus_peak_volume_right_db(busId, 0) 

func update_volume(value : float):
	if AudioServer.get_bus_name(busId) == "Record":
		inputNode.volume_db = value
	else:
		AudioServer.set_bus_volume_db(busId, value)
	volumeSlider.hint_tooltip = str(value) + " dB"
	volumeLabel.text = "     " + str(value) + " dB"
	volumePanel.visible = true
	volumePanel.rect_position.y = -((value + 80) / 124.0 ) * 135.0 +115.0
	volumePanel.get_node('Timer').start()

func volume_slider_input(inputEvent: InputEvent):
	if Input.is_mouse_button_pressed(0):
		volumePanel.get_node('Timer').start()

func switch_solo_toggle(pressed: bool):
	AudioServer.set_bus_solo(busId, pressed)
	if pressed:
		soloButton.modulate = 'ffad00'
	else:
		soloButton.modulate = 'ffffff'

func switch_mute_toggle(pressed: bool):
	if AudioServer.get_bus_name(busId) == "Record":
		inputNode.playing = not pressed
	AudioServer.set_bus_mute(busId, pressed)
	if pressed:
		muteButton.modulate = 'de2424'
	else:
		muteButton.modulate = 'ffffff'

func switch_bypass_toggle(pressed: bool):
	AudioServer.set_bus_bypass_effects(busId, pressed)
	if pressed:
		bypassButton.modulate = '1db3e0'
	else:
		bypassButton.modulate = 'ffffff'
