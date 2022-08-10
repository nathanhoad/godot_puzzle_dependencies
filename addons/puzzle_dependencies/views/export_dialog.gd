tool
extends WindowDialog


signal export_done(save_path)


# Store for use in exporting.
var _types: Array = []


onready var export_formats := $ExportFormats
onready var board_list := $Margin/VBox/Boards
onready var format_list := $Margin/VBox/Formats
onready var save_location_box := $Margin/VBox/HBox/SaveLocation
onready var save_location_button := $Margin/VBox/HBox/SaveLocationButton
onready var boards_alert := $BoardsAcceptDialog
onready var format_alert := $FormatAcceptDialog
onready var export_finished_alert := $ExportAcceptDialog
onready var location_does_not_exist_alert := $LocationDoesNotExistAcceptDialog
onready var export_file_dialog := $ExportFileDialog


func _ready() -> void:
	save_location_button.icon = get_icon("Filesystem", "EditorIcons")


func export_boards(boards: Dictionary, current_board_id: String, types: Array, save_location: String) -> void:
	save_location_box.text = save_location
	export_file_dialog.current_dir = save_location
	_types = types

	populate_board_list(boards, current_board_id)

	populate_format_list()
	
	popup_centered()


func populate_board_list(boards: Dictionary, current_board_id: String) -> void:
	board_list.clear()
	
	var board_index_to_select: int = -1

	for board in boards:
		board_list.add_item(boards[board]["label"])
		board_list.set_item_metadata(board_list.get_item_count() - 1, boards[board])

	board_list.sort_items_by_text()

	for board_idx in range(0, board_list.get_item_count()):
		if board_list.get_item_metadata(board_idx)["id"] == current_board_id:
			board_list.select(board_idx)
			break

	board_list.ensure_current_is_visible()


func populate_format_list() -> void:
	format_list.clear()

	for option in export_formats.get_children():
		format_list.add_item(option.get_name())
		format_list.set_item_metadata(format_list.get_item_count() - 1, option)


func _on_DoneButton_pressed() -> void:
	hide()


func _on_ExportButton_pressed() -> void:
	if format_list.get_selected_id() == -1:
		format_alert.popup_centered()
		return

	var selected_items: PoolIntArray = board_list.get_selected_items()

	if selected_items.empty():
		boards_alert.popup_centered()
		return

	for idx in selected_items:
		var data: Dictionary = board_list.get_item_metadata(idx)

		_export_to_format(data, format_list.get_selected_metadata())


# TODO: Add in export options object to pass on.
func _export_to_format(data: Dictionary, format: Node) -> void:
	if format.has_method("save_to_format"):
		var result: bool = format.save_to_format([data], _types, export_file_dialog.current_path)

		if result:
			export_finished_alert.dialog_text = "Board(s) exported successfully!"

		else:
			export_finished_alert.dialog_text = "One or more boards were unable to be exported."

		# Signal done with the save location as we currently don't track how many successes vs
		# failures for exports there were (other than "all" or "not all").
		emit_signal("export_done", export_file_dialog.current_path)

		export_finished_alert.popup_centered()
	else:
		print("Export format node '%s' has no 'save_to_format' method!" % format.get_name())


func _on_SaveLocationButton_pressed():
	export_file_dialog.popup_centered()


func _on_ExportFileDialog_dir_selected(dir):
	save_location_box.text = dir

