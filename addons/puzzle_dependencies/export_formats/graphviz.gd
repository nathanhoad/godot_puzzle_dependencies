tool
extends Node


# data: An array of dictionaries containing information about any boards to be exported.
# types: An array of dictionaries containing all information about thing types.
# save_location: Location to which the exports should be saved.
func save_to_format(data: Array, types: Array, save_location: String) -> bool:
	var result: bool = false

	for board in data:
		var graphviz_string: String = "strict graph {\n"

		# Nodes
		for thing in board["things"]:
			# Instead of calling out to the settings, we make do with passing in
			# the type information.
			var type = _find_type_by_id(types, thing["type"])
			
			# TODO: Somehow tie these defaults back to what they actually are
			# since "type 0" isn't stored in the config file.
			var fill_color: Color = Color.black
			var font_color: Color = Color.white

			if type:
				fill_color = type.color
				font_color = Color.black if fill_color.v > 0.5 else Color.white

			graphviz_string += "\"%s\" [label=\"%s\", shape=%s, style=%s, fillcolor=\"#%s\", fontcolor=\"#%s\"]\n" \
				% [
					thing["id"], 
					thing["text"],
					"Mrecord",
					"filled",
					fill_color.to_html(false),
					font_color.to_html(false)
				]

		# Edges
		for connection in board["connections"]:
			graphviz_string += "\"%s\" -- \"%s\"\n" % [connection["from"], connection["to"]]

		graphviz_string += "}"

		# For now, if the last save fails, we return false, but this can be reconsidered.
		result = _save_to_disk(graphviz_string, save_location, board["label"])

	return result


func _find_type_by_id(types: Array, id: int):
	for type in types:
		if type.id == id:
			return type

	return null


func _save_to_disk(text: String, path: String, filename: String) -> bool:
	print(path)
	if not path.ends_with("/"):
		path += "/"

	var out_file := File.new()
	var res = out_file.open("%s%s.dot" % [path, filename], File.WRITE)

	if res != OK:
		print("Error opening DOT file for writing.")
		return false

	out_file.store_string(text)
	out_file.close()

	return true
