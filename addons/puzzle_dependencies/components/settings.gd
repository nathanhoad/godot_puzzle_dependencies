tool
extends Node


signal types_changed(types)


const PuzzleConstants = preload("res://addons/puzzle_dependencies/constants.gd")


var config := ConfigFile.new()


func _ready() -> void:
	config.load(PuzzleConstants.CONFIG_PATH)
	if not config.has_section("boards"):
		config.set_value("boards", "boards", {})
		config.set_value("boards", "current_board_id", "")
		config.set_value("boards", "minimap_enabled", true)
		config.set_value("boards", "minimap_size", Vector2(200, 150))
		config.set_value("boards", "use_snap", true)
		config.set_value("boards", "snap_distance", 20)
	
	yield(get_parent(), "ready")
	if not config.has_section("types"):
		var types := [
			{
				id = PuzzleConstants.TYPE_1,
				label = "Type 1",
				color = get_parent().get_color("error_color", "Editor")
			},
			{
				id = PuzzleConstants.TYPE_2,
				label = "Type 2",
				color = get_parent().get_color("accent_color", "Editor")
			},
			{
				id = PuzzleConstants.TYPE_3,
				label = "Type 3",
				color = get_parent().get_color("success_color", "Editor")
			},
			{
				id = PuzzleConstants.TYPE_4,
				label = "Type 4",
				color = get_parent().get_color("warning_color", "Editor")
			}
		]
		for type in types:
			config.set_value("types", str(type.id), type)
		

func reset_config() -> void:
	var dir = Directory.new()
	dir.remove(PuzzleConstants.CONFIG_PATH)


func has_value(key: String) -> bool:
	return config.has_section_key("boards", key)


func get_value(key: String, default):
	return config.get_value("boards", key, default)


func set_value(key: String, value):
	config.set_value("boards", key, value)
	config.save(PuzzleConstants.CONFIG_PATH)


func get_types() -> Array:
	var types = []
	for id in config.get_section_keys("types"):
		types.append(get_type(id.to_int()))
	return types


func get_type(id: int) -> Dictionary:
	return config.get_value("types", str(id))


func set_type(id: int, label: String, color: Color) -> void:
	config.set_value("types", str(id), {
		id = id,
		label = label,
		color = color
	})
	emit_signal("types_changed", get_types())
