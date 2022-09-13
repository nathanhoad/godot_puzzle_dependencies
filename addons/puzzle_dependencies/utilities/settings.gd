@tool
extends Node


const DEFAULT_TYPE = {
	id = 0,
	label = "Default",
	color = Color.BLACK
}


static func set_setting(key: String, value) -> void:
	ProjectSettings.set_setting("puzzle_dependencies/%s" % key, value)
	ProjectSettings.save()


static func get_setting(key: String, default):
	if ProjectSettings.has_setting("puzzle_dependencies/%s" % key):
		return ProjectSettings.get_setting("puzzle_dependencies/%s" % key)
	else:
		return default


static func set_type(id: int, label: String, color: Color) -> void:
	var types = get_types()
	types[id] = {
		id = id,
		label = label,
		color = color
	}
	set_setting("types", types)


static func get_type(id: int) -> Dictionary:
	var types = get_types()
	if types.has(id):
		return types.get(id)
	else:
		return DEFAULT_TYPE


static func get_types() -> Dictionary:
	return get_setting("types", {})


static func remove_type(id: int) -> void:
	var types = get_types()
	types.erase(id)
	set_setting("types", types)
