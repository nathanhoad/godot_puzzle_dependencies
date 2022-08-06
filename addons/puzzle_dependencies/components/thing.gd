tool
extends GraphNode


signal selection_request()
signal popup_menu_request(position)
signal delete_request()


const PuzzleSettings = preload("res://addons/puzzle_dependencies/components/settings.gd")
const PuzzleConstants = preload("res://addons/puzzle_dependencies/constants.gd")


onready var frame_style: StyleBoxFlat = get("custom_styles/frame")
onready var selected_style: StyleBoxFlat = get("custom_styles/selectedframe")
onready var grabber := $VBox/Grabber
onready var text_edit := $VBox/TextEdit


var settings: PuzzleSettings
var board
var type: int = PuzzleConstants.TYPE_DEFAULT setget set_type
var text: String = "" setget set_text
var resized: bool = false
var previous_rect_size: Vector2


func _ready() -> void:
	grabber.texture = get_icon("GuiScrollGrabberHl", "EditorIcons")
	text_edit.set("custom_styles/focus", text_edit.get("custom_styles/normal"))
	text_edit.add_font_override("font", get_font("bold", "EditorFonts"))
	self.type = type


func to_serialized() -> Dictionary:
	return {
		id = name,
		text = text,
		type = type,
		offset = offset,
		rect_size = rect_size
	}


func from_serialized(data: Dictionary) -> void:
	for key in data.keys():
		if key == "id": continue
		set(key, data.get(key))
	text_edit.text = text
	previous_rect_size = rect_size
	resized = false
	self.type = type


### Setters


func set_type(next_type: int) -> void:
	# Settings may have changed colors so we still need to do this
	# even if next_type is the same as the current type
	var background_color = Color.darkgray
	match next_type:
		PuzzleConstants.TYPE_DEFAULT:
			background_color = Color.black
		_:
			background_color = settings.get_type(next_type).color
	
	text_edit.set("custom_colors/font_color", Color.black if background_color.v > 0.5 else Color.white)
	frame_style.bg_color = background_color
	selected_style.bg_color = background_color.lightened(0.1)
	grabber.modulate = background_color.darkened(0.2) if background_color.v > 0.5 else background_color.lightened(0.2)
	
	if type != next_type:
		type = next_type


func set_text(next_text: String) -> void:
	text = next_text
	text_edit.text = text


### Signals


func _on_TextEdit_focus_entered():
	emit_signal("selection_request")


func _on_OptionsButton_pressed():
	emit_signal("options_pressed")


func _on_Thing_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 2:
		emit_signal("popup_menu_request", event.global_position)
		accept_event()
	
	if event is InputEventKey and event.is_pressed():
		match event.as_text():
			"Escape":
				board.graph.grab_focus()


func _on_TextEdit_focus_exited():
	if text_edit.text != text:
		board.undo_redo.create_action("Set thing text")
		board.undo_redo.add_do_method(board, "set_thing_text", name, text_edit.text)
		board.undo_redo.add_undo_method(board, "set_thing_text", name, text)
		board.undo_redo.commit_action()


func _on_Thing_resize_request(new_minsize):
	if not resized:
		resized = true
		previous_rect_size = rect_size
	rect_size = new_minsize


func _on_Thing_mouse_exited():
	if resized:
		resized = false
		board.undo_redo.create_action("Set thing size")
		board.undo_redo.add_do_method(board, "set_thing_size", name, rect_size)
		board.undo_redo.add_undo_method(board, "set_thing_size", name, previous_rect_size)
		board.undo_redo.commit_action()


func _on_Thing_dragged(from, to):
	board.undo_redo.create_action("Move thing")
	board.undo_redo.add_do_method(board, "set_thing_offset", name, to)
	board.undo_redo.add_undo_method(board, "set_thing_offset", name, from)
	board.undo_redo.commit_action()
