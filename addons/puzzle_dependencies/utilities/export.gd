@tool
extends Node


const PuzzleSettings = preload("./settings.gd")


## Export a board in graphviz format
static func as_graphviz(board: Dictionary, path: String) -> void:
	var graphviz: String = "strict graph {\n"

	for thing in board.things:
		var type: Dictionary = PuzzleSettings.get_type(thing.type)
		var fill_color: Color = type.color
		var font_color: Color = Color.BLACK if fill_color.v > 0.5 else Color.WHITE

		graphviz += "\"%s\" [label=\"%s\", shape=%s, style=%s, fillcolor=\"#%s\", fontcolor=\"#%s\"]\n" \
			% [
				thing.id,
				thing.text,
				"Mrecord",
				"filled",
				fill_color.to_html(false),
				font_color.to_html(false)
			]

	for connection in board.connections:
		graphviz += "\"%s\" -- \"%s\"\n" % [connection.from, connection.to]

	graphviz += "}"

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(graphviz)
