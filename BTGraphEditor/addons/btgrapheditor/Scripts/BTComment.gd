## A comment box in a BTGraph.
@tool
extends GraphNode

class_name BTComment

var color_picker : ColorPickerButton
var text_edit : TextEdit
var exit_button : Button
var font_sizes : OptionButton

var undo_redo : EditorUndoRedoManager
var previous_font : int
var previous_font_index : int
var previous_comment : String
var previous_color : Color

var resize_timer : float = 0
var resizing : bool = false

var drag_timer : float = 0
var dragging : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	color_picker = get_node("HSeparator/HBoxContainer/ColorPickerButton")
	text_edit = get_node("TextEdit")
	exit_button = get_node("HSeparator/HBoxContainer/Button")
	font_sizes = get_node("HSeparator/HBoxContainer/OptionButton")
	
	color_picker.color_changed.connect(self.change_color)
	color_picker.popup_closed.connect(self.color_confirmed)
	exit_button.pressed.connect(self.exit)
	
	text_edit.focus_entered.connect(self.focus_on_this)
	text_edit.focus_exited.connect(self.text_edited)
	mouse_entered.connect(self.focus_on_this)
	dragged.connect(self.edit_comment)
	mouse_exited.connect(self.stop_edit_comment)
	font_sizes.item_selected.connect(self.change_font_size)
	
	resize_request.connect(self.resize)
	
	
	if get_parent().get_parent().get_parent().get_parent() is BTGraphDock:
		undo_redo = get_parent().get_parent().get_parent().get_parent().undo_redo
	
	previous_font = 16
	

func resize(new_size):
	if !resizing:
		resizing = true
		var parent = get_parent().get_parent().get_parent().get_parent()
		if parent is BTGraphDock:
			parent.comment_resize_or_drag_start(self)
	resize_timer = 0

func color_confirmed ():
	if self_modulate != previous_color:
		undo_redo.create_action("Changed Color")
		undo_redo.add_do_property(self, "self_modulate", self_modulate)
		undo_redo.add_undo_property(self, "self_modulate", previous_color)
		undo_redo.add_do_property(color_picker, "color", self_modulate)
		undo_redo.add_undo_property(color_picker, "color", previous_color)
		undo_redo.commit_action()
		previous_color = self_modulate
		if get_parent().get_parent().get_parent().get_parent() is BTGraphDock:
			get_parent().get_parent().get_parent().get_parent().save_graph()

func change_color (color):
	self_modulate = color

func change_font_size_no_undo (index):
	var next_font := 0
	if index == 0:
		next_font = 16
	if index == 1:
		next_font = 18
	if index == 2:
		next_font = 20
	if index == 3:
		next_font = 22
	if index == 4:
		next_font = 24
	if index == 5:
		next_font = 26
	if index == 6:
		next_font = 28
	if index == 7:
		next_font = 36
	if index == 8:
		next_font = 48
	if index == 9:
		next_font = 72
	text_edit.add_theme_font_size_override("font_size", next_font)
	previous_font = next_font
	previous_font_index = index

func change_font_size (index):
	var next_font := 0
	if index == 0:
		next_font = 16
	if index == 1:
		next_font = 18
	if index == 2:
		next_font = 20
	if index == 3:
		next_font = 22
	if index == 4:
		next_font = 24
	if index == 5:
		next_font = 26
	if index == 6:
		next_font = 28
	if index == 7:
		next_font = 36
	if index == 8:
		next_font = 48
	if index == 9:
		next_font = 72
	
	text_edit.add_theme_font_size_override("font_size", next_font)
	undo_redo.create_action("Edit Comment Font Size")
	undo_redo.add_do_method(text_edit, "add_theme_font_size_override", "font_size", next_font)
	undo_redo.add_undo_method(text_edit, "add_theme_font_size_override", "font_size", previous_font)
	undo_redo.add_do_property(font_sizes, "selected", index)
	undo_redo.add_undo_property(font_sizes, "selected", previous_font_index)
	undo_redo.commit_action()
	previous_font = next_font
	previous_font_index = index
	if get_parent().get_parent().get_parent().get_parent() is BTGraphDock:
		get_parent().get_parent().get_parent().get_parent().save_graph()

func text_edited ():
	if previous_comment != text_edit.text:
		undo_redo.create_action("Edit Comment")
		undo_redo.add_do_property(text_edit, "text", text_edit.text)
		undo_redo.add_undo_property(text_edit, "text", previous_comment)
		undo_redo.commit_action()
		previous_comment = text_edit.text
		if get_parent().get_parent().get_parent().get_parent() is BTGraphDock:
			get_parent().get_parent().get_parent().get_parent().save_graph()

func focus_on_this ():
	var another_node_selected = false
	for child in get_parent().get_children():
		if (child as Control) != (self as Control):
			var rect = (child as Control).get_global_rect()
			if get_global_mouse_position().x >= rect.position.x and get_global_mouse_position().x <= rect.end.x:
				if get_global_mouse_position().y >= rect.position.y and get_global_mouse_position().y <= rect.end.y:
					release_focus()
					#text_edit.release_focus()
					set_selected(false)
					#child.set_focus_mode(FOCUS_CLICK)
					mouse_filter = Control.MOUSE_FILTER_IGNORE
					text_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
					child.set_selected(true)
					#child.grab_focus()
					another_node_selected = true
					break
	if another_node_selected == false:
		if mouse_filter != Control.MOUSE_FILTER_PASS:
			mouse_filter = Control.MOUSE_FILTER_PASS
			text_edit.grab_focus()
			text_edit.mouse_filter = Control.MOUSE_FILTER_PASS

func edit_comment(from, to):
	text_edit.grab_focus()

func stop_edit_comment():
	if resizing == false && dragging == false:
		text_edit.release_focus()

func exit():
	var parent = get_parent().get_parent().get_parent().get_parent()
	var n_arr : Array[StringName] = [name]
	if parent is BTGraphDock:
		parent.delete_nodes_request(n_arr)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if Input.is_mouse_button_pressed(1):
		var rect = (self as Control).get_global_rect()
		if get_global_mouse_position().x >= rect.position.x and get_global_mouse_position().x <= rect.end.x:
			if get_global_mouse_position().y >= rect.position.y and get_global_mouse_position().y <= rect.end.y:
				if !dragging:
					dragging = true
					var parent = get_parent().get_parent().get_parent().get_parent()
					if parent is BTGraphDock:
						parent.comment_resize_or_drag_start(self)
				drag_timer = 0
	if resize_timer < 0.1:
		resize_timer += delta
	elif resizing:
		resizing = false
		var parent = get_parent().get_parent().get_parent().get_parent()
		if parent is BTGraphDock:
			parent.comment_resize_or_drag_end(self)
			parent.save_graph()
	
	if drag_timer < 0.1:
		drag_timer += delta
	elif dragging:
		dragging = false
		var parent = get_parent().get_parent().get_parent().get_parent()
		if parent is BTGraphDock:
			parent.comment_resize_or_drag_end(self)
			parent.save_graph()
