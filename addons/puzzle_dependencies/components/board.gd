@tool
extends Control


signal change(action_name)


const PuzzleSettings = preload("../utilities/settings.gd")
const PuzzleThingScene = preload("./thing.tscn")
const PuzzleThing = preload("./thing.gd")

const THING_SIZE = Vector2(150, 80)


@onready var graph: GraphEdit = $Graph
@onready var graph_menu := $GraphPopupMenu
@onready var thing_menu := $ThingPopupMenu

var things: Dictionary = {}
var editor_plugin: EditorPlugin
var undo_redo: EditorUndoRedoManager


func _ready() -> void:
	graph.show_zoom_label = true
	graph.add_valid_connection_type(0, 0)

	graph.minimap_enabled = PuzzleSettings.get_setting("minimap_enabled", true)
	graph.minimap_size = PuzzleSettings.get_setting("minimap_size", Vector2(200, 150))
	graph.snapping_enabled = PuzzleSettings.get_setting("snapping_enabled", true)
	graph.snapping_distance = PuzzleSettings.get_setting("snapping_distance", 20)

	thing_menu.board = self


### Helpers


func apply_changes() -> void:
	PuzzleSettings.set_setting("minimap_enabled", graph.minimap_enabled)
	PuzzleSettings.set_setting("minimap_size", graph.minimap_size)
	PuzzleSettings.set_setting("snapping_enabled", graph.snapping_enabled)
	PuzzleSettings.set_setting("snapping_distance", graph.snapping_distance)


func apply_type_changes() -> void:
	for thing in things.values():
		thing.set_type(thing.type)


func redraw() -> void:
	# Sometimes the graph connections are pointing to the wrong position
	# on resized things. This forces it to rerender.
	if things.size() > 0:
		var first_thing = things[things.keys()[0]]
		first_thing.position_offset += Vector2.UP
		await get_tree().process_frame
		first_thing.position_offset -= Vector2.UP


func create_new_board_data() -> Dictionary:
	return {
		id = get_random_id(),
		label = "Untitled board",
		scroll_offset = Vector2.ZERO,
		zoom = 1,
		things = [],
		connections = []
	}


func clear() -> void:
	graph.clear_connections()
	for thing in things.values():
		thing.free()
	things.clear()


func to_serialized() -> Dictionary:
	var editor_scale: float = get_editor_scale()

	var serialized_things: Array = []
	for thing in things.values():
		serialized_things.append(thing.to_serialized(editor_scale))

	var serialized_connections: Array = []
	for connection in graph.get_connection_list():
		serialized_connections.append({
			from = connection.from_node,
			to = connection.to_node
		})

	return {
		scroll_offset = graph.scroll_offset / editor_scale,
		zoom = graph.zoom,
		things = serialized_things,
		connections = serialized_connections
	}


func from_serialized(data: Dictionary) -> void:
	clear()

	var editor_scale: float = get_editor_scale()

	for serialized_thing in data.things:
		_add_thing(serialized_thing.id, serialized_thing)

	for serialized_connection in data.connections:
		graph.connect_node(serialized_connection.from, 0, serialized_connection.to, 0)

	graph.zoom = data.zoom
	graph.scroll_offset = data.scroll_offset * editor_scale


func get_editor_scale() -> float:
	return editor_plugin.get_editor_interface().get_editor_scale()


func get_random_id() -> String:
	randomize()
	seed(Time.get_unix_time_from_system())
	return str(randi() % 1000000).sha1_text().substr(0, 10)


func add_thing_in_center() -> void:
	var editor_scale: float = get_editor_scale()
	var id = get_random_id()

	undo_redo.create_action("Add thing")
	undo_redo.add_do_method(self, "_add_thing", id, {
		position_offset = (graph.scroll_offset / editor_scale + size / editor_scale * 0.5 - THING_SIZE * 0.5) / graph.zoom
	})
	undo_redo.add_undo_method(self, "_delete_thing", id)
	undo_redo.commit_action()


func add_thing(id: String, data: Dictionary = {}) -> void:
	undo_redo.create_action("Add thing")
	undo_redo.add_do_method(self, "_add_thing", id, data)
	undo_redo.add_undo_method(self, "_delete_thing", id)
	undo_redo.commit_action()


func _add_thing(id: String, data: Dictionary = {}) -> void:
	var editor_scale: float = get_editor_scale()

	var thing: PuzzleThing = PuzzleThingScene.instantiate()
	thing.size = THING_SIZE * editor_scale

	thing.board = self
	graph.add_child(thing)

	thing.name = id
	thing.from_serialized(data, editor_scale)

	graph.set_selected(thing)

	things[id] = thing

	thing.selection_request.connect(_on_thing_selection_request.bind(thing))
	thing.popup_menu_request.connect(_on_thing_popup_menu_request.bind(thing))
	thing.delete_requested.connect(_on_thing_delete_requested.bind(thing))


func set_thing_text(id: String, text: String) -> void:
	var thing = things.get(id)
	if is_instance_valid(thing):
		thing.call_deferred("set_text", text)


func set_thing_type(id: String, type: int) -> void:
	var thing = things.get(id)
	if is_instance_valid(thing):
		thing.call_deferred("set_type", type)


func set_thing_size(id: String, size: Vector2) -> void:
	var thing = things.get(id)
	if is_instance_valid(thing):
		thing.call_deferred("set_size", size)


func set_thing_position_offset(id: String, offset: Vector2) -> void:
	var thing = things.get(id)
	if is_instance_valid(thing):
		thing.call_deferred("set_position_offset", offset)


func get_selected_things() -> Array:
	var selected_things: Array = []
	for thing in things.values():
		if thing.selected:
			selected_things.append(thing)

	return selected_things


func delete_selected_things() -> void:
	var things = get_selected_things()

	if things.size() == 0: return

	undo_redo.create_action("Delete things")
	for thing in things:
		var id = thing.name
		for connection in graph.get_connection_list():
			if connection.from_node == id or connection.to_node == id:
				undo_redo.add_do_method(graph, "disconnect_node", connection.from_node, 0, connection.to_node, 0)
				undo_redo.add_undo_method(graph, "connect_node", connection.from_node, 0, connection.to_node, 0)
		undo_redo.add_do_method(self, "_delete_thing", id)
		undo_redo.add_undo_method(self, "_add_thing", id, thing.to_serialized(get_editor_scale()))
	undo_redo.commit_action()


func delete_thing(id: String) -> void:
	undo_redo.create_action("Delete thing")
	for connection in graph.get_connection_list():
		if connection.from_node == id or connection.to_node == id:
			undo_redo.add_do_method(graph, "disconnect_node", connection.from_node, 0, connection.to_node, 0)
			undo_redo.add_undo_method(graph, "connect_node", connection.from_node, 0, connection.to_node, 0)
	undo_redo.add_do_method(self, "_delete_thing", id)
	undo_redo.add_undo_method(self, "_add_thing", id, things.get(id).to_serialized(get_editor_scale()))
	undo_redo.commit_action()


func _delete_thing(id: String) -> void:
	var thing = things.get(id)
	if is_instance_valid(thing):
		thing.free()
		things.erase(id)


## Force all things to reevaluate their type for color
func refresh_things_types() -> void:
	for thing in things.values():
		thing.type = thing.type


### Signals


func _on_thing_selection_request(thing: GraphNode):
	if get_selected_things().size() > 1:
		graph.grab_focus()
	else:
		graph.set_selected(thing)


func _on_thing_popup_menu_request(at_position: Vector2, thing: GraphNode):
	graph.set_selected(thing)
	thing_menu.thing = thing
	thing_menu.popup_at(DisplayServer.mouse_get_position())


func _on_thing_delete_requested(thing: GraphNode):
	call_deferred("delete_thing", thing.name)


func _on_graph_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.as_text():
			"Delete":
				accept_event()
				delete_selected_things()


func _on_graph_popup_request(at_position: Vector2) -> void:
	graph_menu.popup_at(DisplayServer.mouse_get_position())


func _on_graph_connection_request(from: StringName, from_slot: int, to: StringName, to_slot: int) -> void:
	undo_redo.create_action("Connect things")
	undo_redo.add_do_method(graph, "connect_node", from, from_slot, to, to_slot)
	undo_redo.add_undo_method(graph, "disconnect_node", from, from_slot, to, to_slot)
	undo_redo.commit_action()


func _on_graph_connection_from_empty(to: StringName, to_slot: int, release_position: Vector2) -> void:
	var id = get_random_id()

	undo_redo.create_action("Add thing")
	undo_redo.add_do_method(self, "_add_thing", id, {
		position_offset = (graph.scroll_offset + release_position) / get_editor_scale() / graph.zoom - THING_SIZE * Vector2(1, 0.5)
	})
	undo_redo.add_undo_method(self, "_delete_thing", id)
	undo_redo.add_do_method(graph, "connect_node", id, 0, to, to_slot)
	undo_redo.add_undo_method(graph, "disconnect_node", id, 0, to, to_slot)
	undo_redo.commit_action()


func _on_graph_connection_to_empty(from: StringName, from_slot: int, release_position: Vector2) -> void:
	var id = get_random_id()

	undo_redo.create_action("Add thing")
	undo_redo.add_do_method(self, "_add_thing", id, {
		position_offset = (graph.scroll_offset + release_position) / get_editor_scale() / graph.zoom - THING_SIZE * Vector2(0, 0.5)
	})
	undo_redo.add_undo_method(self, "_delete_thing", id)
	undo_redo.add_do_method(graph, "connect_node", from, from_slot, id, 0)
	undo_redo.add_undo_method(graph, "disconnect_node", from, from_slot, id, 0)
	undo_redo.commit_action()


func _on_graph_popup_menu_add_thing(at_position: Vector2, type: int) -> void:
	var id = get_random_id()

	undo_redo.create_action("Add thing")
	undo_redo.add_do_method(self, "_add_thing", id, {
		type = type,
		position_offset = (graph.scroll_offset + at_position - graph.global_position) / get_editor_scale() / graph.zoom
	})
	undo_redo.add_undo_method(self, "_delete_thing", id)
	undo_redo.commit_action()
