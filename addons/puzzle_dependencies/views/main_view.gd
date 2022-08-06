tool
extends Control


onready var update_checker := $UpdateChecker
onready var settings := $Settings
onready var add_board_button := $Margin/VBox/Toolbar/AddBoardButton
onready var boards_menu := $Margin/VBox/Toolbar/BoardsMenu
onready var edit_board_button := $Margin/VBox/Toolbar/EditBoardButton
onready var remove_board_button := $Margin/VBox/Toolbar/RemoveBoardButton
onready var add_thing_button := $Margin/VBox/Toolbar/AddThingButton
onready var remove_thing_button := $Margin/VBox/Toolbar/RemoveThingButton
onready var settings_button := $Margin/VBox/Toolbar/SettingsButton
onready var help_button := $Margin/VBox/Toolbar/HelpButton
onready var update_button := $Margin/VBox/Toolbar/UpdateButton
onready var board := $Margin/VBox/Board
onready var edit_board_dialog := $EditBoardDialog
onready var confirm_remove_board_dialog := $ConfirmRemoveBoardDialog
onready var settings_dialog := $SettingsDialog

var plugin
var undo_redo: UndoRedo setget set_undo_redo

var boards: Dictionary = {}
var current_board_id: String = ""


func _ready() -> void:
	# Set up icons
	add_board_button.icon = get_icon("New", "EditorIcons")
	boards_menu.icon = get_icon("GraphNode", "EditorIcons")
	edit_board_button.icon = get_icon("Edit", "EditorIcons")
	remove_board_button.icon = get_icon("Remove", "EditorIcons")
	add_thing_button.icon = get_icon("ToolAddNode", "EditorIcons")
	remove_thing_button.icon = get_icon("Remove", "EditorIcons")
	settings_button.icon = get_icon("Tools", "EditorIcons")
	help_button.icon = get_icon("Help", "EditorIcons")
	
	# Get boards
	boards = settings.get_value("boards", {})
	go_to_board(settings.get_value("current_board_id", ""))
	if current_board_id != "":
		board.from_serialized(boards.get(current_board_id))
	build_boards_menu()
	
	# Show current version
	var config = ConfigFile.new()
	var err = config.load("res://addons/puzzle_dependencies/plugin.cfg")
	if err == OK:
		$Margin/VBox/Toolbar/VersionLabel.text = "v" + config.get_value("plugin", "version")
	
	# Check for updates
	update_checker.check_for_updates()
	update_button.hide()
	update_button.add_color_override("font_color", get_color("success_color", "Editor"))


func apply_changes() -> void:
	save_board()
	board.apply_changes()	


### Setters


func set_undo_redo(next_undo_redo: UndoRedo) -> void:
	undo_redo = next_undo_redo
	board.undo_redo = next_undo_redo


### Helpers


func go_to_board(id: String) -> void:
	if current_board_id != id:
		save_board()
		
		current_board_id = id
		settings.set_value("current_board_id", id)
		
		if boards.has(current_board_id):
			var board_data = boards.get(current_board_id)
			board.from_serialized(board_data)
			build_boards_menu()
	
	if current_board_id == "":
		board.hide()
		edit_board_button.disabled = true
		remove_board_button.disabled = true
		add_thing_button.disabled = true
		remove_thing_button.disabled = true
	else:
		board.show()
		edit_board_button.disabled = false
		remove_board_button.disabled = false
		add_thing_button.disabled = false
		remove_thing_button.disabled = false


func build_boards_menu() -> void:
	var menu = boards_menu.get_popup()
	menu.clear()
	
	if menu.is_connected("index_pressed", self, "_on_boards_menu_index_pressed"):
		menu.disconnect("index_pressed", self, "_on_boards_menu_index_pressed")
	
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
			menu.add_icon_item(get_icon("GraphNode", "EditorIcons"), label)
		
		if boards.has(current_board_id):
			boards_menu.text = boards.get(current_board_id).label
		menu.connect("index_pressed", self, "_on_boards_menu_index_pressed")


func set_board_data(id: String, data: Dictionary) -> void:
	var board_data = boards.get(id) if boards.has(id) else data
	board_data.merge(data, true)
	boards[id] = board_data
	build_boards_menu()


func save_board() -> void:
	if boards.has(current_board_id):
		var data = board.to_serialized()
		boards[current_board_id].merge(data, true)
	
	settings.set_value("boards", boards)


func remove_board() -> void:
	var board_data = boards.get(current_board_id)
	board_data.merge(board.to_serialized(), true)
	
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


func _on_UpdateChecker_has_update(version, url):
	update_button.show()
	update_button.text = "v" + version + " available!"


func _on_AddBoardButton_pressed():
	edit_board_dialog.edit_board(board.create_new_board_data())


func _on_EditBoardButton_pressed():
	edit_board_dialog.edit_board(boards[current_board_id])


func _on_EditBoardDialog_updated(data):
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


func _on_AddThingButton_pressed():
	board.add_thing_in_center()


func _on_RemoveThingButton_pressed():
	board.delete_selected_things()


func _on_RemoveBoardButton_pressed():
	confirm_remove_board_dialog.dialog_text = "Remove '%s'" % boards.get(current_board_id).label
	confirm_remove_board_dialog.popup_centered()


func _on_ConfirmRemoveBoardDialog_confirmed():
	remove_board()


func _on_MainView_visibility_changed():
	if visible:
		apply_changes()
		board.redraw()


func _on_SettingsButton_pressed():
	settings_dialog.popup_centered()


func _on_HelpButton_pressed():
	OS.shell_open("https://github.com/nathanhoad/godot_puzzle_dependencies")


func _on_UpdateButton_pressed():
	OS.shell_open(update_checker.plugin_url)
