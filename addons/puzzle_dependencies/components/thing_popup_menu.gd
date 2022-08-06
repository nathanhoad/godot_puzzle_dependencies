tool
extends PopupMenu


const PuzzleConstants = preload("res://addons/puzzle_dependencies/constants.gd")
const PuzzleSettings = preload("res://addons/puzzle_dependencies/components/settings.gd")
const PuzzleThing = preload("res://addons/puzzle_dependencies/components/thing.gd")

const ITEM_UNDO = 101
const ITEM_REDO = 102
const ITEM_CUT = 201
const ITEM_COPY = 202
const ITEM_PASTE = 203
const ITEM_DELETE = 301


export(NodePath) var _board := NodePath()

onready var icons := $Icons
onready var board = get_node(_board)
onready var disconnections_menu := $DisconnectionsMenu

var settings: PuzzleSettings
var thing: PuzzleThing


### Helpers


func popup_at(position: Vector2) -> void:
	set_item_disabled(get_item_index(ITEM_UNDO), thing.text_edit.has_undo())
	set_item_disabled(get_item_index(ITEM_REDO), thing.text_edit.has_redo())
	for id in PuzzleConstants.TYPES:
		set_item_checked(get_item_index(id), id == thing.type)
	
	rect_global_position = position
	popup()


func make_label(string: String) -> String:
	if string == "": return "Thing with no content"
	
	var lines = string.split("\n")
	if lines.size() > 1:
		return lines[0].substr(0, 50) + "..."
	elif string.length() > 50:
		return string.substr(0, 50) + "..."
	else:
		return string


### Signals


func _on_ThingPopupMenu_about_to_show():
	clear()
	rect_size = Vector2.ZERO
	
	add_item("Undo", ITEM_UNDO, KEY_MASK_CTRL | KEY_Z)
	set_item_disabled(get_item_index(ITEM_UNDO), not thing.text_edit.has_undo())
	add_item("Redo", ITEM_REDO, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_Z)
	set_item_disabled(get_item_index(ITEM_REDO), not thing.text_edit.has_redo())
	
	add_separator()
	
	add_item("Cut", ITEM_CUT, KEY_MASK_CTRL | KEY_X)
	add_item("Copy", ITEM_COPY, KEY_MASK_CTRL | KEY_C)
	add_item("Paste", ITEM_PASTE, KEY_MASK_CTRL | KEY_V)
	
	add_separator()
	
	# Match the size of another icon in the menu
	var icon_size = get_icon("Remove", "EditorIcons").get_size()
	
	add_radio_check_item("Default", PuzzleConstants.TYPE_DEFAULT)
	set_item_icon(get_item_index(PuzzleConstants.TYPE_DEFAULT), icons.create_color_icon(Color.black, icon_size))
	for id in [PuzzleConstants.TYPE_1, PuzzleConstants.TYPE_2, PuzzleConstants.TYPE_3, PuzzleConstants.TYPE_4]:
		var type = settings.get_type(id)
		add_radio_check_item(type.label, id)
		set_item_icon(get_item_index(id), icons.create_color_icon(type.color, icon_size))
	
	for id in PuzzleConstants.TYPES:
		set_item_checked(get_item_index(id), id == thing.type)
	
	add_separator()
	
	disconnections_menu.clear()
	disconnections_menu.rect_size = Vector2.ZERO
	var connections: Array = board.graph.get_connection_list()
	var left_connections := []
	var right_connections := []
	for index in range(0, connections.size()):
		var connection = connections[index]
		if connection.to == thing.name:
			var from_thing = board.things.get(connection.from)
			left_connections.append({
				index = index,
				label = make_label(from_thing.text)
			})
		elif connection.from == thing.name:
			var to_thing = board.things.get(connection.to)
			right_connections.append({
				index = index,
				label = make_label(to_thing.text)
			})
	
	if left_connections.size() > 0 or right_connections.size() > 0:
		add_submenu_item("Disconnect", disconnections_menu.name)
		if left_connections.size() > 0:
			disconnections_menu.add_separator("Left")
			for item in left_connections:
				disconnections_menu.add_item(item.label, item.index)
	
		if right_connections.size() > 0:
			disconnections_menu.add_separator("Right")
			for item in right_connections:
				disconnections_menu.add_item(item.label, item.index)
		
		add_separator()
	
	add_icon_item(get_icon("Remove", "EditorIcons"), "Remove", ITEM_DELETE)


func _on_ThingPopupMenu_id_pressed(id):
	match id:
		ITEM_UNDO:
			thing.text_edit.undo()
		ITEM_REDO:
			thing.text_edit.redo()
		ITEM_CUT:
			thing.text_edit.cut()
		ITEM_COPY:
			thing.text_edit.copy()
		ITEM_PASTE:
			thing.text_edit.paste()
		ITEM_DELETE:
			thing.emit_signal("delete_request")
		PuzzleConstants.TYPE_DEFAULT, \
		PuzzleConstants.TYPE_1, \
		PuzzleConstants.TYPE_2, \
		PuzzleConstants.TYPE_3, \
		PuzzleConstants.TYPE_4:
			board.undo_redo.create_action("Change thing type")
			board.undo_redo.add_do_method(board, "set_thing_type", thing.name, id)
			board.undo_redo.add_undo_method(board, "set_thing_type", thing.name, thing.type)
			board.undo_redo.commit_action()


func _on_DisconnectionsMenu_id_pressed(id):
	var connection = board.graph.get_connection_list()[id]
	
	board.undo_redo.create_action("Disconnect things")
	board.undo_redo.add_do_method(board.graph, "disconnect_node", connection.from, connection.from_port, connection.to, connection.to_port)
	board.undo_redo.add_undo_method(board.graph, "connect_node", connection.from, connection.from_port, connection.to, connection.to_port)
	board.undo_redo.commit_action()
