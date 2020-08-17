extends VBoxContainer

var settingsContainer

func _ready():
	settingsContainer = $HBoxSettingsContainer
	var muteButton = settingsContainer.get_node("MuteButton")
	var volumeSlider = settingsContainer.get_node("VolumeSlider")
	var soloButton = settingsContainer.get_node("SoloButton")
	self.connect("mouse_entered", self, "on_entered")
	self.connect("mouse_exited", self, "on_exited")
	self.connect("focus_entered", self, "on_entered")
	self.connect("focus_exited", self, "on_exited")
	$NameField.connect("focus_entered", self, "on_entered")
	$NameField.connect("focus_exited", self, "on_exited")
	muteButton.connect("focus_entered", self, "on_entered")
	muteButton.connect("focus_exited", self, "on_exited")
	volumeSlider.connect("focus_entered", self, "on_entered")
	volumeSlider.connect("focus_exited", self, "on_exited")
	soloButton.connect("focus_entered", self, "on_entered")
	soloButton.connect("focus_exited", self, "on_exited")

func _process(delta):
	$Background.margin_top = 0

func on_entered():
	settingsContainer.visible = true
	yield(get_tree(), "idle_frame")
	$Background.margin_top = 0

func on_exited():
	settingsContainer.visible = false
	yield(get_tree(), "idle_frame")
	$Background.margin_top = 0
