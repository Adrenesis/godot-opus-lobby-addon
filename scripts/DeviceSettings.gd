extends ColorRect

var confirmButton : Button
var cancelButton : Button
var outputButton : OptionButton
var inputButton : OptionButton
var oldOutput : String
var oldInput : String

func _ready():
	confirmButton = get_node("VBoxContainer/HBoxContainer/ConfirmButton")
	cancelButton = get_node("VBoxContainer/HBoxContainer/CancelButton")
	outputButton = get_node("VBoxContainer/OutputOptionButton")
	inputButton = get_node("VBoxContainer/InputOptionButton")
	for device in AudioServer.get_device_list():
		outputButton.add_item(device)
	for device in AudioServer.capture_get_device_list():
		inputButton.add_item(device)
	
	outputButton.select(AudioServer.get_device_list().find(AudioServer.get_device()))
	inputButton.select(AudioServer.capture_get_device_list().find(AudioServer.capture_get_device()))
	var _error
	confirmButton.connect("pressed", self, "on_confirm_pressed")
	cancelButton.connect("pressed", self, "on_cancel_pressed")
	if not outputButton.is_connected("item_selected", self, "on_output_selected"):
		_error = outputButton.connect("item_selected", self, "on_output_selected")
	if not inputButton.is_connected("item_selected", self, "on_input_selected"):
		_error = inputButton.connect("item_selected", self, "on_input_selected")
	self.connect("visibility_changed", self, "on_visibility_changed")

func on_visibility_changed():
#	pass
	if visible and OS.get_ticks_msec() > 500:
		if outputButton.is_connected("item_selected", self, "on_output_selected"):
			outputButton.disconnect("item_selected", self, "on_output_selected")
		if inputButton.is_connected("item_selected", self, "on_input_selected"):
			inputButton.disconnect("item_selected", self, "on_input_selected")
		for id in range(outputButton.get_item_count()):
			outputButton.remove_item(0)
		for id in range(inputButton.get_item_count()):
			inputButton.remove_item(0)
		for device in AudioServer.get_device_list():
			outputButton.add_item(device)
		for device in AudioServer.capture_get_device_list():
			inputButton.add_item(device)
		oldOutput = AudioServer.get_device()
		oldInput = AudioServer.capture_get_device()

		print((AudioServer.get_device_list().find(AudioServer.get_device())))
		outputButton.selected = (AudioServer.get_device_list().find(oldOutput))
		inputButton.selected =(AudioServer.capture_get_device_list().find(oldInput))
		var _error
		if not outputButton.is_connected("item_selected", self, "on_output_selected"):
			_error = outputButton.connect("item_selected", self, "on_output_selected")
		if not inputButton.is_connected("item_selected", self, "on_input_selected"):
			_error = inputButton.connect("item_selected", self, "on_input_selected")

func on_cancel_pressed():
	print("what?" + str((AudioServer.get_device_list().find(oldOutput))))
	outputButton.selected =(AudioServer.get_device_list().find(oldOutput))
	inputButton.selected =(AudioServer.capture_get_device_list().find(oldInput))
	AudioServer.device  = (AudioServer.get_device_list()[outputButton.selected])
	AudioServer.capture_set_device(AudioServer.capture_get_device_list()[inputButton.selected])
	self.visible = false
	get_node('../ShowDeviceSettings').pressed = false


func on_confirm_pressed():
	self.visible = false
	get_node('../ShowDeviceSettings').pressed = false

func on_output_selected(item_idx):
	AudioServer.device  = (AudioServer.get_device_list()[item_idx])

func on_input_selected(item_idx):
	AudioServer.capture_set_device(AudioServer.capture_get_device_list()[item_idx])
