@tool
extends Button
class_name BehaviorVariable

var text_edit : TextEdit

@export var int_img : Texture2D
@export var flt_img : Texture2D
@export var bool_img : Texture2D

var datatype : int = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_child_count() > 0:
		text_edit = get_node("TextEdit")
		text_edit.text_changed.connect(self.text_changed)
		text_edit.focus_exited.connect(self.text_end)
	pass # Replace with function body.


func set_bool_img():
	icon = bool_img
	datatype = 0
	if get_parent().get_parent().get_parent().get_parent().get_parent().get_parent() is BTGraphDock:
		get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().save_graph()

func set_int_img():
	icon = int_img
	datatype = 1
	if get_parent().get_parent().get_parent().get_parent().get_parent().get_parent() is BTGraphDock:
		get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().save_graph()

func set_flt_img():
	icon = flt_img
	datatype = 2
	if get_parent().get_parent().get_parent().get_parent().get_parent().get_parent() is BTGraphDock:
		get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().save_graph()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func text_changed():
	var c = text_edit.get_caret_column()
	text_edit.text = str(text_edit.text).replace("\t", "")
	if text_edit.text.contains("\n"):
		text_edit.text = str(text_edit.text).replace("\n", "")
		text_edit.release_focus()
	text_edit.set_caret_column(c)
	
	pass

func text_end():
	text = text_edit.text
	text_edit.visible = false
	var check = get_parent().get_parent().get_parent().name == "Variables"
	if get_parent().get_parent().get_parent().get_parent().get_parent().get_parent() is BTGraphDock:
		get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().save_graph()
		get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().update_variable_and_signal_nodes_keep_index(check, text)

func _get_drag_data(at_position):
	return {"type": "behavior_variable", "data_type": datatype, "name": text}
