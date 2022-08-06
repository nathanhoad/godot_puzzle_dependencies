tool
extends AcceptDialog


onready var color_picker := $ColorPicker

var type: Dictionary


### Signals


func _on_EditTypeDialog_about_to_show():
	color_picker.color = type.color


func _on_ColorPicker_color_changed(color):
	type.color = color
