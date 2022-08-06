tool
extends PopupMenu


signal add_thing(position, type)


const PuzzleConstants = preload("res://addons/puzzle_dependencies/constants.gd")
const PuzzleSettings = preload("res://addons/puzzle_dependencies/components/settings.gd")


onready var icons := $Icons
onready var settings: PuzzleSettings


### Helpers


func popup_at(position: Vector2) -> void:
	clear()
	
	var icon_size = get_icon("Remove", "EditorIcons").get_size()
	add_icon_item(icons.create_color_icon(Color.black, icon_size), "Add Default thing here", PuzzleConstants.TYPE_DEFAULT)
	for id in [PuzzleConstants.TYPE_1, PuzzleConstants.TYPE_2, PuzzleConstants.TYPE_3, PuzzleConstants.TYPE_4]:
		var type = settings.get_type(id)
		add_icon_item(icons.create_color_icon(type.color, icon_size), "Add %s thing here" % type.label, id)
	
	rect_global_position = position
	popup()


### Signals


func _on_GraphPopupMenu_id_pressed(id):
	emit_signal("add_thing", rect_global_position, id)
