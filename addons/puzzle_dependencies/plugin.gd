@tool
extends EditorPlugin


const MainViewScene = preload("./views/main_view.tscn")
const MainView = preload("./views/main_view.gd")
const PuzzleSettings = preload("./utilities/settings.gd")


var main_view: MainView


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		main_view = MainViewScene.instantiate()
		main_view.editor_plugin = self
		get_editor_interface().get_editor_main_screen().add_child(main_view)
		main_view.undo_redo = get_undo_redo()
		_make_visible(false)

		# Set up some default types
		if PuzzleSettings.get_types().size() == 0:
			PuzzleSettings.set_type(0, "Type 1", Color.BLACK)
			PuzzleSettings.set_type(1, "Type 2", Color("ff786b"))
			PuzzleSettings.set_type(2, "Type 3", Color("bd93f9"))
			PuzzleSettings.set_type(3, "Type 4", Color("73f280"))
			PuzzleSettings.set_type(4, "Type 5", Color("ffde66"))


func _exit_tree() -> void:
	if is_instance_valid(main_view):
		main_view.queue_free()


func _has_main_screen() -> bool:
	return true


func _make_visible(next_visible: bool) -> void:
	if is_instance_valid(main_view):
		main_view.visible = next_visible


func _get_plugin_name() -> String:
	return "Puzzles"


func _get_plugin_icon() -> Texture2D:
	return create_main_icon()


func create_main_icon(scale: float = 1.0) -> Texture2D:
	var size: Vector2 = Vector2(16, 16) * get_editor_interface().get_editor_scale() * scale
	var base_color: Color = get_editor_interface().get_editor_main_screen().get_theme_color("base_color", "Editor")
	var theme: String = "light" if base_color.v > 0.5 else "dark"
	var base_icon = load(get_script().resource_path.get_base_dir() + "/assets/icons/icon_%s.svg" % theme) as Texture2D
	var image: Image = base_icon.get_image()
	image.resize(size.x, size.y, Image.INTERPOLATE_TRILINEAR)
	return ImageTexture.create_from_image(image)


func _apply_changes() -> void:
	if is_instance_valid(main_view):
		main_view.apply_changes()
