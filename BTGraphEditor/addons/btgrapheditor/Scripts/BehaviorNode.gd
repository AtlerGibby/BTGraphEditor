## A single node in a behavior tree.
@tool
extends GraphNode
class_name BehaviorNode

var exit_button : Button
var options_1 : OptionButton
var options_2 : OptionButton
var text_edit : TextEdit
var undo_redo : EditorUndoRedoManager

var previous_comment : String
var previous_option : int
var previous_option_2 : int

var loading_rid : String

@export var isVariableNode : bool
@export var isSignalNode : bool
@export var isBoolNode : bool

@export var enabled_color : Color
@export var disabled_color : Color

# Called when the node enters the scene tree for the first time.
func _ready():
	exit_button = get_node("Spacer/Button")
	if has_node("OptionButton"):
		options_1 = get_node("OptionButton")
		options_1.item_selected.connect(self.option_changed)
		#previous_option = options_1.selected
	if has_node("OptionButton2"):
		options_2 = get_node("OptionButton2")
		options_2.item_selected.connect(self.option_2_changed)
		#previous_option_2 = options_2.selected
	if has_node("TextEdit"):
		text_edit = get_node("TextEdit")
		text_edit.focus_exited.connect(self.text_changed)
		#previous_comment = text_edit.text
	
	exit_button.pressed.connect(self.exit)
	
	if get_parent().get_parent().get_parent().get_parent() is BTGraphDock:
		undo_redo = get_parent().get_parent().get_parent().get_parent().undo_redo

func text_editability(index):
	print(title)
	if title == "Variable":
		if index == 2 or index == 3:
			text_edit.editable = true
			text_edit.self_modulate = Color(1,1,1,1)
		else:
			text_edit.editable = false
			text_edit.self_modulate = Color(0.5,0.5,0.5,0.5)
	if title == "Wait":
		if index == 0 or index == 1:
			text_edit.editable = true
			text_edit.self_modulate = Color(1,1,1,1)
		else:
			text_edit.editable = false
			text_edit.self_modulate = Color(0.5,0.5,0.5,0.5)


func option_changed(index):
	if index != previous_option:
		undo_redo.create_action("Changed Option")
		undo_redo.add_do_property(options_1, "selected", index)
		undo_redo.add_undo_property(options_1, "selected", previous_option)
		undo_redo.commit_action()
		previous_option = index
		text_editability(index)
	if isBoolNode:
		if index == 2:
			set_slot_color_left(3, disabled_color)
			get_node("Label2").self_modulate = Color(0.5, 0.5, 0.5, 0.5)
		else:
			set_slot_color_left(3, enabled_color)
			get_node("Label2").self_modulate = Color.WHITE
	if get_parent().get_parent().get_parent().get_parent() is BTGraphDock:
		get_parent().get_parent().get_parent().get_parent().save_graph()

func option_2_changed(index):
	if index != previous_option_2:
		undo_redo.create_action("Changed Option")
		undo_redo.add_do_property(options_2, "selected", index)
		undo_redo.add_undo_property(options_2, "selected", previous_option_2)
		undo_redo.commit_action()
		previous_option_2 = index
	if get_parent().get_parent().get_parent().get_parent() is BTGraphDock:
		get_parent().get_parent().get_parent().get_parent().save_graph()

func text_changed():
	var new_text = ""
	var one_decimal = false
	for c in text_edit.text:
		if c.is_valid_int():
			new_text += c
		if c == ".":
			if one_decimal == false:
				new_text += c
				one_decimal = true
			else:
				break
	text_edit.text = new_text
	if previous_comment != text_edit.text:
		undo_redo.create_action("Edit Parameter")
		undo_redo.add_do_property(text_edit, "text", text_edit.text)
		undo_redo.add_undo_property(text_edit, "text", previous_comment)
		undo_redo.commit_action()
		previous_comment = text_edit.text
	if get_parent().get_parent().get_parent().get_parent() is BTGraphDock:
		get_parent().get_parent().get_parent().get_parent().save_graph()

func delete_request():
	queue_free()

func get_list_of_signals():
	var node := Object.new()
	var dict = node.get_signal_list()

func exit():
	var parent = get_parent().get_parent().get_parent().get_parent()
	var n_arr : Array[StringName] = [name]
	if parent is BTGraphDock:
		parent.delete_nodes_request(n_arr)
