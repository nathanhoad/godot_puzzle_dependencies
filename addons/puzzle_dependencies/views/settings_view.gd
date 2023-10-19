@tool
extends VBoxContainer


const PuzzleSettings = preload("../utilities/settings.gd")

@onready var add_type_button: Button = $Toolbar/AddTypeButton
@onready var types_list: Tree = $TypesList
@onready var color_picker_dialog: AcceptDialog = $ColorPickerDialog
@onready var color_picker: ColorPicker = $ColorPickerDialog/ColorPicker

var dialog: AcceptDialog
var item_being_edited: TreeItem

var root: TreeItem

## Build the types list and show the settings dialogue
func popup_centered() -> void:
	add_type_button.icon = get_theme_icon("Add", "EditorIcons")

	types_list.clear()
	root = types_list.create_item()

	for type in PuzzleSettings.get_types().values():
		add_tree_item(type)

	root.get_child(0).set_button_disabled(3, 0, root.get_child_count() == 1)

	types_list.set_column_expand(0, true)
	types_list.set_column_custom_minimum_width(0, 200)
	types_list.set_column_expand(1, false)
	types_list.set_column_custom_minimum_width(1, 40)
	types_list.set_column_expand(2, false)
	types_list.set_column_custom_minimum_width(2, 30)

	dialog.popup_centered()


func add_tree_item(type: Dictionary) -> void:
	var item: TreeItem = types_list.create_item(root)
	item.set_text(0, type.label)
	item.set_editable(0, true)
	item.set_custom_bg_color(1, type.color)
	item.add_button(2, get_theme_icon("ColorPick", "EditorIcons"))
	item.add_button(3, get_theme_icon("Remove", "EditorIcons"))
	item.set_meta("type", type.id)


### Signals


func _on_types_list_item_edited() -> void:
	var item: TreeItem = types_list.get_edited()
	PuzzleSettings.set_type(item.get_meta("type"), item.get_text(0), item.get_custom_bg_color(1))


func _on_types_list_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match column:
		2:
			item_being_edited = item
			color_picker_dialog.popup_centered()
		3:
			PuzzleSettings.remove_type(item.get_meta("type"))
			root.remove_child(item)
			root.get_child(0).set_button_disabled(3, 0, root.get_child_count() == 1)


func _on_color_picker_dialog_confirmed() -> void:
	var type: Dictionary = PuzzleSettings.get_type(item_being_edited.get_meta("type"))
	item_being_edited.set_custom_bg_color(1, color_picker.color)
	PuzzleSettings.set_type(type.id, type.label, color_picker.color)


func _on_add_type_button_pressed() -> void:
	var id: int = randi() % 10000
	var type: Dictionary = {
		id = id,
		label = "Type %d" % id,
		color = Color.BLACK
	}
	PuzzleSettings.set_type(type.id, type.label, type.color)
	add_tree_item(type)
