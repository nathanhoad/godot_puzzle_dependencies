tool
extends ConfirmationDialog


signal updated(data)


onready var label_edit := $VBox/LabelEdit

var data: Dictionary = {}


func _ready() -> void:
	register_text_enter(label_edit)


func edit_board(board_data: Dictionary) -> void:
	label_edit.text = board_data.label
	data = board_data
	popup_centered()
	label_edit.grab_focus()
	label_edit.select_all()


### Signals


func _on_EditBoardDialog_confirmed():
	var next_data := {}
	next_data.merge(data)
	next_data.merge({ label = label_edit.text }, true)
	emit_signal("updated", next_data)
