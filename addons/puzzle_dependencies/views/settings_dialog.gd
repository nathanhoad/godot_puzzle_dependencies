tool
extends WindowDialog


const PuzzleSettings = preload("res://addons/puzzle_dependencies/components/settings.gd")


export(NodePath) var _settings := NodePath()

onready var settings: PuzzleSettings = get_node(_settings)
onready var colors_list := $Margin/VBox/ColorsList
onready var edit_type_dialog := $EditTypeDialog

var item_being_edited: TreeItem


func _on_SettingsDialog_about_to_show():
	colors_list.clear()
	var root = colors_list.create_item()
	
	for type in settings.get_types():
		var item = colors_list.create_item(root)
		item.set_text(0, type.label)
		item.set_editable(0, true)
		item.set_custom_bg_color(1, type.color)
		item.add_button(2, get_icon("ColorPick", "EditorIcons"))
		item.set_meta("type", type.id)
	
	colors_list.set_column_expand(0, true)
	colors_list.set_column_min_width(0, 200)
	colors_list.set_column_expand(1, false)
	colors_list.set_column_min_width(1, 40)
	colors_list.set_column_expand(2, false)
	colors_list.set_column_min_width(2, 30)


func _on_DoneButton_pressed():
	hide()


func _on_ColorsList_item_edited():
	var item = colors_list.get_edited()
	settings.set_type(item.get_meta("type"), item.get_text(0), item.get_custom_bg_color(1))


func _on_ColorsList_button_pressed(item, column, id):
	item_being_edited = item
	edit_type_dialog.type = settings.get_type(item.get_meta("type"))
	edit_type_dialog.popup_centered()


func _on_EditTypeDialog_confirmed():
	var type = edit_type_dialog.type
	item_being_edited.set_custom_bg_color(1, type.color)
	settings.set_type(type.id, type.label, type.color)
