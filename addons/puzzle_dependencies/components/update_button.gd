@tool
extends Button


const OPEN_URL = "https://github.com/nathanhoad/godot_puzzle_dependencies"
const REMOTE_CONFIG_URL = "https://raw.githubusercontent.com/nathanhoad/godot_puzzle_dependencies/main/addons/puzzle_dependencies/plugin.cfg"
const LOCAL_CONFIG_PATH = "res://addons/puzzle_dependencies/plugin.cfg"


@onready var http_request: HTTPRequest = $HTTPRequest
@onready var version_on_load: String = get_version()

# The main editor plugin
var editor_plugin: EditorPlugin

# A lambda that gets called just before refreshing the plugin. Return false to stop the reload.
var on_before_refresh: Callable = func on_before_refresh(): return true


func _ready() -> void:
	hide()
	apply_theme()
	check_for_remote_update()
	

# Check for updates on GitHub
func check_for_remote_update() -> void:
	http_request.request(REMOTE_CONFIG_URL)


# Check for local file updates and restart the plugin if found
func check_for_local_update() -> void:
	var next_version = get_version()
	if version_to_number(next_version) > version_to_number(version_on_load):
		var will_refresh = on_before_refresh.call()
		if will_refresh:
			if editor_plugin.get_editor_interface().get_resource_filesystem().filesystem_changed.is_connected(_on_filesystem_changed):
				editor_plugin.get_editor_interface().get_resource_filesystem().filesystem_changed.disconnect(_on_filesystem_changed)
			print_rich("[b]Updated Puzzle Dependencies to v%s[b]" % next_version)
			editor_plugin.get_editor_interface().call_deferred("set_plugin_enabled", "puzzle_dependencies", true)
			editor_plugin.get_editor_interface().set_plugin_enabled("puzzle_dependencies", false)


# Get the current version
func get_version() -> String:
	var config: ConfigFile = ConfigFile.new()
	config.load(LOCAL_CONFIG_PATH)
	return config.get_value("plugin", "version")


# Convert a version number to an actually comparable number
func version_to_number(version: String) -> int:
	var bits = version.split(".")
	return bits[0].to_int() * 1000000 + bits[1].to_int() * 1000 + bits[2].to_int()


func apply_theme() -> void:
	add_theme_color_override("font_color", get_theme_color("success_color", "Editor"))
	add_theme_color_override("font_hover_color", get_theme_color("success_color", "Editor"))


### Signals


func _on_filesystem_changed() -> void:
	check_for_local_update()


func _on_update_button_theme_changed() -> void:
	apply_theme()


func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS: return
	
	# Parse the version number from the remote config file
	var response = body.get_string_from_utf8()
	var regex = RegEx.new()
	regex.compile("version=\"(?<version>\\d+\\.\\d+\\.\\d+)\"")
	var found = regex.search(response)
	
	if not found: return
	
	var next_version = found.strings[found.names.get("version")]
	if version_to_number(next_version) > version_to_number(version_on_load):
		text = "v%s available" % next_version
		show()
		# Wait for the local files to be updated
		editor_plugin.get_editor_interface().get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed)


func _on_update_button_pressed() -> void:
	OS.shell_open(OPEN_URL)
