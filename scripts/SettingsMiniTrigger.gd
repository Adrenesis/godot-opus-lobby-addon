extends VBoxContainer

var settingsContainer

func _ready():
	settingsContainer = $HBoxSettingsContainer
	self.connect("mouse_entered", self, "on_entered")
	self.connect("mouse_exited", self, "on_exited")

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
