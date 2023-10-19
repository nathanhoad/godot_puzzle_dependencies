@tool
extends PopupMenu


signal add_thing(position: Vector2, type: int)


const PuzzleSettings = preload("../utilities/settings.gd")
const PuzzleIcons = preload("../utilities/icons.gd")


## Show the popup menu at a position
func popup_at(next_position: Vector2) -> void:
	position = next_position
	popup()


### Signals


func _on_graph_popup_menu_about_to_popup() -> void:
	clear()
	size = Vector2.ZERO
	var icon_size = get_theme_icon("Remove", "EditorIcons").get_size()
	for type in PuzzleSettings.get_types().values():
		add_icon_item(PuzzleIcons.create_color_icon(type.color, icon_size), "Add %s thing here" % type.label, type.id)


func _on_graph_popup_menu_id_pressed(id: int) -> void:
	emit_signal("add_thing", position, id)
