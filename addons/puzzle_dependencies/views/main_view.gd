@tool
extends Control


signal types_change(types: Array[Dictionary])


const PuzzleSettings = preload("../utilities/settings.gd")
const PuzzleExport = preload("../utilities/export.gd")


@onready var add_board_button: Button = $Margin/VBox/Toolbar/AddBoardButton
@onready var boards_menu: MenuButton = $Margin/VBox/Toolbar/BoardsMenu
@onready var edit_board_button: Button = $Margin/VBox/Toolbar/EditBoardButton
@onready var remove_board_button: Button = $Margin/VBox/Toolbar/RemoveBoardButton
@onready var export_button: Button = $Margin/VBox/Toolbar/ExportButton
@onready var add_thing_button: Button = $Margin/VBox/Toolbar/AddThingButton
@onready var remove_thing_button: Button = $Margin/VBox/Toolbar/RemoveThingButton
@onready var settings_button: Button = $Margin/VBox/Toolbar/SettingsButton
@onready var docs_button: Button = $Margin/VBox/Toolbar/DocsButton
@onready var update_button := $Margin/VBox/Toolbar/UpdateButton
@onready var version_label: Label = $Margin/VBox/Toolbar/VersionLabel
@onready var board := $Margin/VBox/Board
@onready var edit_board_dialog := $EditBoardDialog
@onready var confirm_remove_board_dialog: AcceptDialog = $ConfirmRemoveBoardDialog
@onready var settings_view := $SettingsDialog/SettingsView
@onready var export_dialog: FileDialog = $ExportDialog
@onready var updated_dialog: AcceptDialog = $UpdatedDialog

var editor_plugin: EditorPlugin

var undo_redo: EditorUndoRedoManager:
	set(next_undo_redo):
		undo_redo = next_undo_redo
		board.undo_redo = next_undo_redo
	get:
		return undo_redo

var boards: Dictionary = {}
var current_board_id: String = ""


func _ready() -> void:
	call_deferred("apply_theme")

	board.editor_plugin = editor_plugin

	# Set up the update checker
	version_label.text = "v%s" % update_button.get_version()
	update_button.editor_plugin = editor_plugin
	update_button.on_before_refresh = func on_before_refresh():
		# Touch a file
		var touch: FileAccess = FileAccess.open("user://just_updated.txt", FileAccess.WRITE)
		touch.store_string("just updated")
		return true

	# Did we just load from an addon version refresh?
	var just_updated: bool = FileAccess.file_exists("user://just_updated.txt")
	if just_updated:
		DirAccess.remove_absolute("user://just_updated.txt")
		call_deferred("load_from_version_refresh")

	# Get boards
	boards = PuzzleSettings.get_setting("boards", {})
	go_to_board(PuzzleSettings.get_setting("current_board_id", ""))
	if current_board_id != "" and boards.has(current_board_id):
		board.from_serialized(boards.get(current_board_id))
	else:
		current_board_id = ""

	settings_view.dialog = $SettingsDialog


func apply_changes() -> void:
	if is_instance_valid(board):
		save_board()
		board.apply_changes()


### Helpers


func load_from_version_refresh() -> void:
	editor_plugin.get_editor_interface().set_main_screen_editor("Puzzles")
	updated_dialog.popup_centered()


func apply_theme() -> void:
	# Simple check if onready
	if is_instance_valid(add_board_button):
		add_board_button.icon = get_theme_icon("New", "EditorIcons")
		boards_menu.icon = get_theme_icon("GraphNode", "EditorIcons")
		edit_board_button.icon = get_theme_icon("Edit", "EditorIcons")
		remove_board_button.icon = get_theme_icon("Remove", "EditorIcons")
		add_thing_button.icon = get_theme_icon("ToolAddNode", "EditorIcons")
		add_thing_button.text = "Add thing"
		remove_thing_button.icon = get_theme_icon("Remove", "EditorIcons")
		settings_button.icon = get_theme_icon("Tools", "EditorIcons")
		export_button.icon = get_theme_icon("ExternalLink", "EditorIcons")
		export_button.text = "Export"
		docs_button.icon = get_theme_icon("Help", "EditorIcons")
		docs_button.text = "Docs"

		update_button.apply_theme()


func go_to_board(id: String) -> void:
	if current_board_id != id:
		save_board()

		current_board_id = id
		PuzzleSettings.set_setting("current_board_id", id)

		if boards.has(current_board_id):
			var board_data = boards.get(current_board_id)
			board.from_serialized(board_data)

	if current_board_id == "":
		board.hide()
		edit_board_button.disabled = true
		remove_board_button.disabled = true
		add_thing_button.disabled = true
		remove_thing_button.disabled = true
		export_button.disabled = true
	else:
		board.show()
		edit_board_button.disabled = false
		remove_board_button.disabled = false
		add_thing_button.disabled = false
		remove_thing_button.disabled = false
		export_button.disabled = false

	build_boards_menu()


func build_boards_menu() -> void:
	var menu: PopupMenu = boards_menu.get_popup()
	menu.clear()

	if menu.index_pressed.is_connected(_on_boards_menu_index_pressed):
		menu.index_pressed.disconnect(_on_boards_menu_index_pressed)

	if boards.size() == 0:
		boards_menu.text = "No boards yet"
		boards_menu.disabled = true
	else:
		boards_menu.disabled = false

		# Add board labels to the menu in alphabetical order
		var labels := []
		for board_data in boards.values():
			labels.append(board_data.label)
		labels.sort()
		for label in labels:
			menu.add_icon_item(get_theme_icon("GraphNode", "EditorIcons"), label)

		if boards.has(current_board_id):
			boards_menu.text = boards.get(current_board_id).label
		menu.index_pressed.connect(_on_boards_menu_index_pressed)


func set_board_data(id: String, data: Dictionary) -> void:
	var board_data = boards.get(id) if boards.has(id) else data
	for key in data.keys():
		board_data[key] = data.get(key)
	boards[id] = board_data
	build_boards_menu()


func save_board() -> void:
	if boards.has(current_board_id):
		var data = board.to_serialized()
		for key in data.keys():
			boards[current_board_id][key] = data.get(key)
	PuzzleSettings.set_setting("boards", boards)


func remove_board() -> void:
	var board_data = boards.get(current_board_id)
	var undo_board_data = board.to_serialized()
	for key in undo_board_data.keys():
		board_data[key] = undo_board_data.get(key)

	undo_redo.create_action("Delete board")
	undo_redo.add_do_method(self, "_remove_board", current_board_id)
	undo_redo.add_undo_method(self, "_unremove_board", current_board_id, board_data)
	undo_redo.commit_action()


func _remove_board(id: String) -> void:
	boards.erase(id)
	go_to_board(boards.keys().front() if boards.size() > 0 else "")
	build_boards_menu()


func _unremove_board(id: String, data: Dictionary) -> void:
	boards[id] = data
	build_boards_menu()
	go_to_board(id)


### Signals


func _on_boards_menu_index_pressed(index):
	var popup = boards_menu.get_popup()
	var label = popup.get_item_text(index)
	for board_data in boards.values():
		if board_data.label == label:
			undo_redo.create_action("Change board")
			undo_redo.add_do_method(self, "go_to_board", board_data.id)
			undo_redo.add_undo_method(self, "go_to_board", current_board_id)
			undo_redo.commit_action()


func _on_main_view_theme_changed() -> void:
	apply_theme()


func _on_main_view_visibility_changed() -> void:
	if visible:
		apply_changes()
		if is_instance_valid(board):
			board.redraw()


func _on_add_board_button_pressed() -> void:
	edit_board_dialog.edit_board(board.create_new_board_data())


func _on_boards_menu_about_to_popup() -> void:
	build_boards_menu()


func _on_edit_board_button_pressed() -> void:
	edit_board_dialog.edit_board(boards[current_board_id])


func _on_edit_board_dialog_updated(data: Dictionary) -> void:
	if boards.has(data.id):
		undo_redo.create_action("Set board label")
		undo_redo.add_do_method(self, "set_board_data", data.id, { label = data.label })
		undo_redo.add_undo_method(self, "set_board_data", data.id, { label = boards.get(data.id).label })
		undo_redo.commit_action()
	else:
		undo_redo.create_action("Set board label")
		undo_redo.add_do_method(self, "set_board_data", data.id, data)
		undo_redo.add_undo_method(self, "_remove_board", data.id)
		undo_redo.add_do_method(self, "go_to_board", data.id)
		undo_redo.add_undo_method(self, "go_to_board", current_board_id)
		undo_redo.commit_action()


func _on_remove_board_button_pressed() -> void:
	confirm_remove_board_dialog.dialog_text = "Remove '%s'" % boards.get(current_board_id).label
	confirm_remove_board_dialog.popup_centered()


func _on_add_thing_button_pressed() -> void:
	board.add_thing_in_center()


func _on_remove_thing_button_pressed() -> void:
	board.delete_selected_things()


func _on_confirm_remove_board_dialog_confirmed() -> void:
	remove_board()


func _on_settings_button_pressed() -> void:
	settings_view.popup_centered()


func _on_settings_dialog_confirmed() -> void:
	board.apply_type_changes()


func _on_docs_button_pressed() -> void:
	OS.shell_open("https://github.com/nathanhoad/godot_puzzle_dependencies")


func _on_export_button_pressed() -> void:
	save_board()
	export_dialog.current_path = PuzzleSettings.get_setting("last_export_path", "")
	export_dialog.popup_centered()


func _on_export_dialog_file_selected(path: String) -> void:
	if path != "":
		PuzzleSettings.set_setting("last_export_path", path)
		PuzzleExport.as_graphviz(board.to_serialized(), path)

