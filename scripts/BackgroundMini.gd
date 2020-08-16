tool
extends ColorRect

func _ready():
	self.connect("item_rect_changed", self, "on_resized")

func on_resized():
	margin_top = 0
