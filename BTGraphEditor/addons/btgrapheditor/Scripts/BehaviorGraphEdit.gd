## The GraphEdit for the main dock of the BTGraph Editor.
@tool
extends GraphEdit
class_name BehaviorGraphEdit

@export var variale_node : PackedScene
@export var signal_node : PackedScene

func _can_drop_data(position, data):
	if typeof(data) == TYPE_DICTIONARY:
		if data["type"] == "behavior_variable":
			if get_global_mouse_position().x >= get_viewport_rect().position.x and get_global_mouse_position().x <= get_viewport_rect().end.x:
				if get_global_mouse_position().y >= get_viewport_rect().position.y and get_global_mouse_position().y <= get_viewport_rect().end.y:
					return true
	return false

func _drop_data(at_position, data):
	if data["data_type"] == -1:
		var new_node := signal_node.instantiate()
		add_child(new_node)
		new_node.position_offset = (get_local_mouse_position() + scroll_offset) / zoom
		for child in get_children():
			if child is BehaviorNode:
				if (child as BehaviorNode).isSignalNode:
					new_sig(child.get_node("OptionButton"), data["name"], new_node)
	else:
		var new_node := variale_node.instantiate()
		add_child(new_node)
		new_node.position_offset = (get_local_mouse_position() + scroll_offset) / zoom
		for child in get_children():
			if child is BehaviorNode:
				if (child as BehaviorNode).isVariableNode:
					new_var(child.get_node("OptionButton"), data["name"], new_node)


func new_var(ob : OptionButton, current_name : String, current_node : Control):
	var index := ob.get_selected_id()
	var index_text := ob.get_item_text(index)
	ob.clear()
	var variables = get_parent().get_node("Variables/ScrollContainer/VBoxContainer").get_children()
	ob.add_item("True")
	ob.add_item("False")
	ob.add_item("Integer Parameter")
	ob.add_item("Float Parameter")
	if (ob.get_parent() as Control) == current_node:
		index = 4
	var var_count := 0
	for v in variables:
		if v.is_queued_for_deletion() == false:
			ob.add_item("Variable: " + v.text)
			if (ob.get_parent() as Control) == current_node:
				if v.text == current_name:
					ob.select(index)
				index += 1
			var_count += 1
	if (ob.get_parent() as Control) != current_node:
		for id in range(ob.item_count):
			if ob.get_item_text(id) == index_text:
				ob.select(id)
				break

func new_sig(ob : OptionButton, current_name : String, current_node : Control):
	var index := ob.get_selected_id()
	var index_text := ob.get_item_text(index)
	ob.clear()
	ob.add_item(" ")
	var signals = get_parent().get_node("Actions/ScrollContainer/VBoxContainer").get_children()
	if (ob.get_parent() as Control) == current_node:
		index = 1
	var var_count := 0
	for s in signals:
		if s.is_queued_for_deletion() == false:
			ob.add_item("Signal: " + s.text)
			if (ob.get_parent() as Control) == current_node:
				if s.text == current_name:
					ob.select(index)
				index += 1
		var_count += 1
	if (ob.get_parent() as Control) != current_node:
		for id in range(ob.item_count):
			if ob.get_item_text(id) == index_text:
				ob.select(id)
				break
