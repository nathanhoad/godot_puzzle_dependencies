@tool
extends GraphNode


signal selection_request()
signal popup_menu_request(position: Vector2)
signal delete_requested()


const PuzzleSettings = preload("../utilities/settings.gd")


@onready var frame_style: StyleBoxFlat = get("theme_override_styles/panel")
@onready var selected_style: StyleBoxFlat = get("theme_override_styles/panel_selected")
@onready var grabber: TextureRect = $VBox/Grabber
@onready var text_edit: TextEdit = $VBox/TextEdit

var board

var type: int = 0:
	get:
		return type

var text: String = "":
	get:
		return text

var has_resized: bool = false

var previous_size: Vector2


func _ready() -> void:
	call_deferred("apply_theme")
	text_edit.set("theme_override_styles/focus", text_edit.get("theme_override_styles/normal"))
	set_type(type)
	frame_style = frame_style.duplicate()
	set("theme_override_styles/panel", frame_style)
	selected_style = selected_style.duplicate()
	set("theme_override_styles/panel_selected", selected_style)


func apply_theme() -> void:
	if is_instance_valid(grabber):
		grabber.texture = get_theme_icon("GuiScrollGrabberHl", "EditorIcons")
		grabber.custom_minimum_size.y = grabber.texture.get_height()
	if is_instance_valid(text_edit):
		text_edit.add_theme_font_override("font", get_theme_font("bold", "EditorFonts"))


func set_text(next_text: String) -> void:
	text = next_text
	text_edit.text = text


func set_type(next_type: int) -> void:
	type = next_type
	# Settings may have changed colors so we still need to do this
	# even if next_type is the same as the current type
	var background_color: Color = PuzzleSettings.get_type(next_type).color
	text_edit.set("theme_override_colors/font_color", Color.BLACK if background_color.v > 0.5 else Color.WHITE)
	frame_style.bg_color = background_color
	selected_style.bg_color = background_color.lightened(0.1)
	grabber.modulate = background_color.darkened(0.2) if background_color.v > 0.5 else background_color.lightened(0.3)


func to_serialized(scale: float) -> Dictionary:
	return {
		id = name,
		text = text,
		type = type,
		position_offset = position_offset / scale,
		size = size / scale
	}


func from_serialized(data: Dictionary, scale: float) -> void:
	if data.has("text"):
		set("text", data.text)
	if data.has("position_offset"):
		set("position_offset", data.position_offset * scale)
	if data.has("size"):
		set("size", data.size * scale)
	if data.has("type"):
		set_type(data.type)

	text_edit.text = text
	previous_size = size
	has_resized = false


### Signals


func _on_thing_theme_changed() -> void:
	apply_theme()


func _on_thing_dragged(from: Vector2, to: Vector2) -> void:
	board.undo_redo.create_action("Move thing")
	board.undo_redo.add_do_method(board, "set_thing_position_offset", name, to)
	board.undo_redo.add_undo_method(board, "set_thing_position_offset", name, from)
	board.undo_redo.commit_action()


func _on_thing_mouse_exited() -> void:
	if has_resized:
		has_resized = false
		board.undo_redo.create_action("Set thing size")
		board.undo_redo.add_do_method(board, "set_thing_size", name, size)
		board.undo_redo.add_undo_method(board, "set_thing_size", name, previous_size)
		board.undo_redo.commit_action()

func _on_thing_resize_request(new_minsize: Vector2) -> void:
	if not has_resized:
		has_resized = true
		previous_size = size
	size = new_minsize


func _on_text_edit_focus_entered() -> void:
	selection_request.emit()


func _on_text_edit_focus_exited() -> void:
	if text_edit.text != text:
		board.undo_redo.create_action("Set thing text")
		board.undo_redo.add_do_method(board, "set_thing_text", name, text_edit.text)
		board.undo_redo.add_undo_method(board, "set_thing_text", name, text)
		board.undo_redo.commit_action()


func _on_thing_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 2:
		popup_menu_request.emit(event.global_position)
		accept_event()

	if event is InputEventKey and event.is_pressed():
		match event.as_text():
			"Escape":
				board.graph.grab_focus()
