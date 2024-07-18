## The main dock for the BTGraph Editor.
@tool
extends Control
class_name BTGraphDock

var behavior_node : PackedScene = load("res://addons/btgrapheditor/Components/BehaviorNode.tscn")
var root_node : PackedScene = load("res://addons/btgrapheditor/Components/RootNode.tscn")

var behavior_variale : PackedScene = load("res://addons/btgrapheditor/Components/BehaviorVariable.tscn")
var statement_node : PackedScene = load("res://addons/btgrapheditor/Components/StatementNode.tscn")
var bool_node : PackedScene = load("res://addons/btgrapheditor/Components/BoolNode.tscn")
var if_node : PackedScene = load("res://addons/btgrapheditor/Components/IfNode.tscn")
var sequencer_node : PackedScene = load("res://addons/btgrapheditor/Components/SequencerNode.tscn")
var action_node : PackedScene = load("res://addons/btgrapheditor/Components/ActionNode.tscn")
var wait_node : PackedScene = load("res://addons/btgrapheditor/Components/WaitNode.tscn")
var variable_node : PackedScene = load("res://addons/btgrapheditor/Components/VariableNode.tscn")
var signal_node : PackedScene = load("res://addons/btgrapheditor/Components/SignalNode.tscn")
var comment : PackedScene = load("res://addons/btgrapheditor/Components/Comment.tscn")

var graph_data_resource : BTGraph

var statement_button : Button
var bool_button : Button
var if_button : Button
var sequencer_button : Button
var action_button : Button
var wait_button : Button
var comment_button : Button

var variables : Control
var signals : Control
var drop_box : Control

var new_var_button : Button
var new_signal_button : Button

var load_bt_button : Button

var graph_edit : GraphEdit

var selected_nodes : Array
var copied_nodes : Array

var selected_nodes_start_positions : PackedVector2Array
var selected_nodes_end_positions : PackedVector2Array
var selected_nodes_that_moved : Array
var move_history : Array
var move_history_index : int

var removed_nodes_list : Array

var popup : PopupMenu
var file_dialog : FileDialog
var selected_behavior_variable : BehaviorVariable
var plugin_enabled : bool
var resource_path : String

var ref_to_root : GraphNode

var undo_redo : EditorUndoRedoManager

# Called when the node enters the scene tree for the first time.
func _ready():
	statement_button = get_node("VBoxContainer/HBoxContainer2/Button")
	bool_button = get_node("VBoxContainer/HBoxContainer2/Button2")
	if_button = get_node("VBoxContainer/HBoxContainer2/Button3")
	sequencer_button = get_node("VBoxContainer/HBoxContainer2/Button4")
	action_button = get_node("VBoxContainer/HBoxContainer2/Button5")
	wait_button = get_node("VBoxContainer/HBoxContainer2/Button6")
	comment_button = get_node("VBoxContainer/HBoxContainer2/Button7")
	
	variables = get_node("VBoxContainer/HBoxContainer/Variables")
	signals = get_node("VBoxContainer/HBoxContainer/Actions")
	drop_box = get_node("VBoxContainer/HBoxContainer2/HBoxContainer/Label")
	
	graph_edit = get_node("VBoxContainer/HBoxContainer/GraphEdit")
	popup = get_node("PopupMenu")
	file_dialog = get_node("FileDialog")
	
	new_var_button = get_node("VBoxContainer/HBoxContainer/Variables/Label/Button")
	new_signal_button = get_node("VBoxContainer/HBoxContainer/Actions/Label/Button")
	
	load_bt_button = get_node("VBoxContainer/HBoxContainer2/Button8")
	
	statement_button.pressed.connect(self.add_statement)
	bool_button.pressed.connect(self.add_bool)
	if_button.pressed.connect(self.add_if)
	sequencer_button.pressed.connect(self.add_selector)
	action_button.pressed.connect(self.add_action)
	wait_button.pressed.connect(self.add_wait)
	comment_button.pressed.connect(self.add_comment)
	
	new_var_button.pressed.connect(self.new_var)
	new_signal_button.pressed.connect(self.new_sig)
	
	load_bt_button.pressed.connect(self.load_bt)
	
	graph_edit.delete_nodes_request.connect(self.delete_nodes_request)
	graph_edit.connection_request.connect(self.connection_request)
	graph_edit.disconnection_request.connect(self.disconnection_request)
	graph_edit.connection_from_empty.connect(self.connection_from_empty)
	graph_edit.copy_nodes_request.connect(self.copy_nodes_request)
	graph_edit.paste_nodes_request.connect(self.paste_nodes_request)
	graph_edit.node_selected.connect(self.node_selected)
	graph_edit.node_deselected.connect(self.node_deselected)
	graph_edit.begin_node_move.connect(self.record_node_move)
	graph_edit.end_node_move.connect(self.stop_record_node_move)
	graph_edit.connection_drag_started.connect(self.connection_start)
	graph_edit.connection_drag_ended.connect(self.connection_end)
	mouse_entered.connect(self.check_for_resource)
	
	popup.id_pressed.connect(self.select_popup_option)
	file_dialog.confirmed.connect(self.open_bt_no_args)
	file_dialog.file_selected.connect(self.open_bt)
	
	
	var rfs = ResourceFormatSaver.new()
	ResourceSaver.add_resource_format_saver(rfs)
	
	plugin_enabled = true
	if graph_data_resource == null && plugin_enabled:
		disable_advanced_ai_plugin()


func undo_redo_save():
	save_graph()

func connection_start(from_node, from_port, is_output):
	for child in graph_edit.get_children():
		if child is BTComment:
			child.selectable = false

func connection_end():
	for child in graph_edit.get_children():
		if child is BTComment:
			child.selectable = true

func disable_advanced_ai_plugin():
	graph_edit.process_mode = Node.PROCESS_MODE_DISABLED
	graph_edit.modulate = Color(1,1,1,0.2)
	get_node("VBoxContainer/HBoxContainer/Variables").process_mode = Node.PROCESS_MODE_DISABLED
	get_node("VBoxContainer/HBoxContainer/Actions").process_mode = Node.PROCESS_MODE_DISABLED
	get_node("VBoxContainer/HBoxContainer/Variables").modulate = Color(1,1,1,0.2)
	get_node("VBoxContainer/HBoxContainer/Actions").modulate = Color(1,1,1,0.2)
	statement_button.process_mode = Node.PROCESS_MODE_DISABLED
	bool_button.process_mode = Node.PROCESS_MODE_DISABLED
	if_button.process_mode = Node.PROCESS_MODE_DISABLED
	sequencer_button.process_mode = Node.PROCESS_MODE_DISABLED
	action_button.process_mode = Node.PROCESS_MODE_DISABLED
	wait_button.process_mode = Node.PROCESS_MODE_DISABLED
	comment_button.process_mode = Node.PROCESS_MODE_DISABLED
	statement_button.modulate = Color(1,1,1,0.2)
	bool_button.modulate = Color(1,1,1,0.2)
	if_button.modulate = Color(1,1,1,0.2)
	sequencer_button.modulate = Color(1,1,1,0.2)
	action_button.modulate = Color(1,1,1,0.2)
	wait_button.modulate = Color(1,1,1,0.2)
	comment_button.modulate = Color(1,1,1,0.2)
	get_node("VBoxContainer/HBoxContainer2/HBoxContainer/Label").process_mode = Node.PROCESS_MODE_DISABLED
	get_node("VBoxContainer/HBoxContainer2/HBoxContainer/Label").modulate = Color(1,1,1,0.2)
	plugin_enabled = false
	get_node("VBoxContainer/HBoxContainer2/Label").text = "---"
	for child in graph_edit.get_children():
		child.queue_free()
	graph_edit.clear_connections()
	clear_undo_redo_history()

func enable_advanced_ai_plugin():
	graph_edit.process_mode = Node.PROCESS_MODE_INHERIT
	graph_edit.modulate = Color(1,1,1,1)
	get_node("VBoxContainer/HBoxContainer/Variables").process_mode = Node.PROCESS_MODE_INHERIT
	get_node("VBoxContainer/HBoxContainer/Actions").process_mode = Node.PROCESS_MODE_INHERIT
	get_node("VBoxContainer/HBoxContainer/Variables").modulate = Color(1,1,1,1)
	get_node("VBoxContainer/HBoxContainer/Actions").modulate = Color(1,1,1,1)
	statement_button.process_mode = Node.PROCESS_MODE_INHERIT
	bool_button.process_mode = Node.PROCESS_MODE_INHERIT
	if_button.process_mode = Node.PROCESS_MODE_INHERIT
	sequencer_button.process_mode = Node.PROCESS_MODE_INHERIT
	action_button.process_mode = Node.PROCESS_MODE_INHERIT
	wait_button.process_mode = Node.PROCESS_MODE_INHERIT
	comment_button.process_mode = Node.PROCESS_MODE_INHERIT
	statement_button.modulate = Color(1,1,1,1)
	bool_button.modulate = Color(1,1,1,1)
	if_button.modulate = Color(1,1,1,1)
	sequencer_button.modulate = Color(1,1,1,1)
	action_button.modulate = Color(1,1,1,1)
	wait_button.modulate = Color(1,1,1,1)
	comment_button.modulate = Color(1,1,1,1)
	get_node("VBoxContainer/HBoxContainer2/HBoxContainer/Label").process_mode = Node.PROCESS_MODE_INHERIT
	get_node("VBoxContainer/HBoxContainer2/HBoxContainer/Label").modulate = Color(1,1,1,1)
	plugin_enabled = true


func check_for_resource():
	if plugin_enabled:
		if ResourceLoader.exists(resource_path) == false:
			disable_advanced_ai_plugin()
			graph_data_resource = null

func comment_resize_or_drag_start(exception):
	for child in graph_edit.get_children():
		if child != exception:
			child.selectable = false
			child.draggable = false
			child.process_mode = Node.PROCESS_MODE_DISABLED

func comment_resize_or_drag_end(exception):
	for child in graph_edit.get_children():
		if child != exception:
			child.selectable = true
			child.draggable = true
			child.process_mode = Node.PROCESS_MODE_INHERIT


func load_bt():
	file_dialog.popup()

func open_bt_no_args():
	var path = file_dialog.current_path
	if path == resource_path:
		return
		
	print("PATH: " + path)
	
	graph_data_resource = BTGraph.new()
	resource_path = path
	var is_valid = graph_data_resource.validate_resource(path)
	if is_valid:
		graph_data_resource.load_data(path)
		enable_advanced_ai_plugin()
		init_graph(graph_data_resource)
		get_node("VBoxContainer/HBoxContainer2/Label").text = path.split("/")[-1]
	else:
		graph_data_resource = null

func open_bt(file_path):
	if file_path == resource_path:
		return
	
	print("PATH: " + file_path)
	
	graph_data_resource = BTGraph.new()

	resource_path = file_path
	var is_valid = graph_data_resource.validate_resource(file_path)
	if is_valid:
		graph_data_resource.load_data(file_path)
		enable_advanced_ai_plugin()
		init_graph(graph_data_resource)
		get_node("VBoxContainer/HBoxContainer2/Label").text = file_path.split("/")[-1]
	else:
		graph_data_resource = null

func add_statement():
	var zoom = (1 - (graph_edit.zoom_max / graph_edit.zoom)) / 2
	var new_node := statement_node.instantiate()
	var pos = graph_edit.get_viewport_rect().position + graph_edit.size / 3
	graph_edit.add_child(new_node)
	new_node.position_offset = (pos + graph_edit.scroll_offset) / graph_edit.zoom
	undo_redo.create_action("Add Statement Node")
	undo_redo.add_undo_method(graph_edit, "remove_child", new_node)
	undo_redo.add_do_method(graph_edit, "add_child", new_node)
	undo_redo.add_do_method(self, "remove_list_check_up")
	undo_redo.commit_action(false)
	save_graph()

func add_bool():
	var zoom = graph_edit.zoom_max / graph_edit.zoom
	var new_node := bool_node.instantiate()
	var pos = graph_edit.get_viewport_rect().position + graph_edit.size / 3
	graph_edit.add_child(new_node)
	new_node.position_offset = (pos + graph_edit.scroll_offset) / graph_edit.zoom
	undo_redo.create_action("Add Bool Node")
	undo_redo.add_undo_method(graph_edit, "remove_child", new_node)
	undo_redo.add_do_method(graph_edit, "add_child", new_node)
	undo_redo.add_do_method(self, "remove_list_check_up")
	undo_redo.commit_action(false)
	save_graph()

func add_if():
	var zoom = graph_edit.zoom_max / graph_edit.zoom
	var new_node := if_node.instantiate()
	var pos = graph_edit.get_viewport_rect().position + graph_edit.size / 3
	graph_edit.add_child(new_node)
	new_node.position_offset = (pos + graph_edit.scroll_offset) / graph_edit.zoom
	undo_redo.create_action("Add If Node")
	undo_redo.add_undo_method(graph_edit, "remove_child", new_node)
	undo_redo.add_do_method(graph_edit, "add_child", new_node)
	undo_redo.add_do_method(self, "remove_list_check_up")
	undo_redo.commit_action(false)
	save_graph()

func add_selector():
	var zoom = graph_edit.zoom_max / graph_edit.zoom
	var new_node := sequencer_node.instantiate()
	var pos = graph_edit.get_viewport_rect().position + graph_edit.size / 3
	graph_edit.add_child(new_node)
	new_node.position_offset = (pos + graph_edit.scroll_offset) / graph_edit.zoom
	undo_redo.create_action("Add Selector Node")
	undo_redo.add_undo_method(graph_edit, "remove_child", new_node)
	undo_redo.add_do_method(graph_edit, "add_child", new_node)
	undo_redo.add_do_method(self, "remove_list_check_up")
	undo_redo.commit_action(false)
	save_graph()

func add_action():
	var zoom = graph_edit.zoom_max / graph_edit.zoom
	var new_node := action_node.instantiate()
	var pos = graph_edit.get_viewport_rect().position + graph_edit.size / 3
	graph_edit.add_child(new_node)
	new_node.position_offset = (pos + graph_edit.scroll_offset) / graph_edit.zoom
	new_node.get_node("OptionButton").clear()
	new_node.get_node("OptionButton").add_item(" ")
	
	var gd_script = get_node("VBoxContainer/HBoxContainer2/HBoxContainer/Label").gd_script
	if gd_script != null:
		var methods = gd_script.new().get_method_list()
		for method in methods:
			if  method["name"].substr(0,9) == "BTAction_":
				new_node.get_node("OptionButton").add_item("Action: " + method["name"])
				
	undo_redo.create_action("Add Action Node")
	undo_redo.add_undo_method(graph_edit, "remove_child", new_node)
	undo_redo.add_do_method(graph_edit, "add_child", new_node)
	undo_redo.add_do_method(self, "remove_list_check_up")
	undo_redo.commit_action(false)
	save_graph()

func add_wait():
	var zoom = graph_edit.zoom_max - graph_edit.zoom
	var new_node := wait_node.instantiate()
	var pos = graph_edit.get_viewport_rect().position + graph_edit.size / 3
	graph_edit.add_child(new_node)
	new_node.position_offset = (pos + graph_edit.scroll_offset) / graph_edit.zoom
	new_node.get_node("OptionButton").clear()
	new_node.get_node("OptionButton").add_item("Time: Seconds")
	new_node.get_node("OptionButton").add_item("Time: Miliseconds")
	
	var gd_script = get_node("VBoxContainer/HBoxContainer2/HBoxContainer/Label").gd_script
	if gd_script != null:
		var signals = gd_script.new().get_signal_list()
		for sig in signals:
			new_node.get_node("OptionButton").add_item("Signal: " + sig["name"])
	
	undo_redo.create_action("Add Wait Node")
	undo_redo.add_undo_method(graph_edit, "remove_child", new_node)
	undo_redo.add_do_method(graph_edit, "add_child", new_node)
	undo_redo.add_do_method(self, "remove_list_check_up")
	undo_redo.commit_action(false)
	save_graph()


func add_comment():
	var new_node := comment.instantiate()
	var pos = graph_edit.get_viewport_rect().position + graph_edit.size / 3
	graph_edit.add_child(new_node)
	new_node.position_offset = (pos + graph_edit.scroll_offset) / graph_edit.zoom
	undo_redo.create_action("Add Comment Node")
	undo_redo.add_undo_method(graph_edit, "remove_child", new_node)
	undo_redo.add_do_method(graph_edit, "add_child", new_node)
	undo_redo.add_do_method(self, "remove_list_check_up")
	undo_redo.commit_action(false)
	save_graph()

func clear_undo_redo_history():
	if undo_redo != null:
		undo_redo.get_history_undo_redo(undo_redo.get_object_history_id(graph_edit)).clear_history()
		for node in removed_nodes_list:
			if node.is_queued_for_deletion() == false:
				node.queue_free()
		removed_nodes_list.clear()
		selected_nodes.clear()
		selected_nodes_start_positions.clear()
		selected_nodes_end_positions.clear()
		selected_nodes_that_moved.clear()
		move_history.clear()

func new_var():
	var new_var := behavior_variale.instantiate()
	get_node("VBoxContainer/HBoxContainer/Variables/ScrollContainer/VBoxContainer").add_child(new_var)
	new_var.text = "Variable " + str(new_var.get_parent().get_child_count() - 1)
	new_var.set_bool_img()
	update_variable_and_signal_nodes(true)
	undo_redo.create_action("Add Variable Node")
	undo_redo.add_undo_method(graph_edit, "remove_child", new_var)
	undo_redo.add_do_method(graph_edit, "add_child", new_var)
	undo_redo.add_do_method(self, "remove_list_check_up")
	undo_redo.commit_action(false)
	save_graph()

func new_sig():
	var new_var := behavior_variale.instantiate()
	get_node("VBoxContainer/HBoxContainer/Actions/ScrollContainer/VBoxContainer").add_child(new_var)
	new_var.text = "Signal " + str(new_var.get_parent().get_child_count() - 1)
	update_variable_and_signal_nodes(false)
	undo_redo.create_action("Add Signal Node")
	undo_redo.add_undo_method(graph_edit, "remove_child", new_var)
	undo_redo.add_do_method(graph_edit, "add_child", new_var)
	undo_redo.add_do_method(self, "remove_list_check_up")
	undo_redo.commit_action(false)
	save_graph()

func copy_nodes_request():
	copied_nodes.clear()
	#print("COPY")
	for node in selected_nodes:
		copied_nodes.append(node)

func paste_nodes_request():
	var new_nodes := Array([])
	undo_redo.create_action("Paste Nodes")
	for node in copied_nodes:
		if node.is_queued_for_deletion() == false and node != null:
			var new_node := (node.duplicate() as GraphNode)
			graph_edit.add_child(new_node)
			#new_node.title = node.title
			new_node.position_offset = node.position_offset + Vector2(128, 128)
			new_nodes.append(new_node)
			node.selected = false
			new_node.selected = true
			undo_redo.add_undo_method(graph_edit, "remove_child", new_node)
			undo_redo.add_do_method(graph_edit, "add_child", new_node)
			undo_redo.add_do_method(self, "remove_list_check_up")
	
	if len(copied_nodes) <= 1:
		return
	
	for n in range(len(copied_nodes)):
		for con in graph_edit.get_connection_list():
			for n2 in range(len(copied_nodes)):
				if copied_nodes[n] != copied_nodes[n2]:
					if con.to_node == copied_nodes[n2].name and con.from_node == copied_nodes[n].name:
						graph_edit.connect_node(new_nodes[n].name, con.from_port, new_nodes[n2].name, con.to_port)
						undo_redo.add_do_method(graph_edit, "connect_node", new_nodes[n].name, con.from_port, new_nodes[n2].name, con.to_port)
						undo_redo.add_undo_method(graph_edit, "disconnect_node", new_nodes[n].name, con.from_port, new_nodes[n2].name, con.to_port)
	
	undo_redo.commit_action(false)
	save_graph()

func node_selected(node):
	for n in  selected_nodes:
		if n == node:
			return
	if node.name == "RootNode":
		return
	selected_nodes.append(node)

func node_deselected(node):
	for n in range(len(selected_nodes)):
		if selected_nodes[n] == node:
			selected_nodes.remove_at(n)
			#print("DESelected: " + node.name)
			break

func connection_request(from_node, from_port, to_node, to_port):
	if from_node == to_node:
		return
	for con in graph_edit.get_connection_list():
		if con.to_node == to_node and con.to_port == to_port:
			graph_edit.disconnect_node(con.from_node, con.from_port, to_node, to_port)
	graph_edit.connect_node(from_node, from_port, to_node, to_port)
	print(graph_edit.get_node("RootNode"))
	
	undo_redo.create_action("Connect Nodes")
	undo_redo.add_do_method(graph_edit, "connect_node", from_node, from_port, to_node, to_port)
	undo_redo.add_undo_method(graph_edit, "disconnect_node", from_node, from_port, to_node, to_port)
	undo_redo.commit_action(false)
	save_graph()

func disconnection_request(from_node, from_port, to_node, to_port):
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
	
	undo_redo.create_action("Disconnect Nodes")
	undo_redo.add_do_method(graph_edit, "disconnect_node", from_node, from_port, to_node, to_port)
	undo_redo.add_undo_method(graph_edit, "connect_node", from_node, from_port, to_node, to_port)
	undo_redo.commit_action(false)
	save_graph()

func connection_to_empty(from_node, from_port, release_position):
	for con in graph_edit.get_connection_list():
		if con.from_node == from_node and con.from_port == from_port:
			disconnection_request(con.from_node, con.from_port, con.to_node, con.to_port)

func connection_from_empty(to_node, to_port, release_position):
	for con in graph_edit.get_connection_list():
		if con.to_node == to_node and con.to_port == to_port:
			disconnection_request(con.from_node, con.from_port, con.to_node, con.to_port)

func delete_nodes_request (nodes : Array[StringName]):
	undo_redo.create_action("Delete Nodes")
	for node in nodes:
		if node == "RootNode":
			continue
		for child in graph_edit.get_children():
			if child.name == node:
				for con in graph_edit.get_connection_list():
					if con.to_node == child.name or con.from_node == child.name:
						undo_redo.add_do_method(graph_edit, "disconnect_node", con.from_node, con.from_port, con.to_node, con.to_port)
						undo_redo.add_undo_method(graph_edit, "connect_node", con.from_node, con.from_port, con.to_node, con.to_port)
						graph_edit.disconnect_node(con.from_node, con.from_port, con.to_node, con.to_port)
				#child.queue_free()
				undo_redo.add_do_method(graph_edit, "remove_child", child)
				undo_redo.add_undo_method(graph_edit, "add_child", child, child.get_index())
				undo_redo.add_undo_method(self, "remove_list_check_up")
				removed_nodes_list.append(child)
				if selected_nodes.has(child):
					selected_nodes.erase(child)
				
	undo_redo.commit_action()
	save_graph()

func remove_list_check_up():
	for node in removed_nodes_list:
		if node.get_parent() == graph_edit:
			removed_nodes_list.erase(node)

func _input(event):
	# Right Click Menu
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		for child in get_node("VBoxContainer/HBoxContainer/Variables/ScrollContainer/VBoxContainer").get_children():
			var rect = (child as Control).get_global_rect()
			if get_global_mouse_position().x >= rect.position.x and get_global_mouse_position().x <= rect.end.x:
				if get_global_mouse_position().y >= rect.position.y and get_global_mouse_position().y <= rect.end.y:
					popup.popup(Rect2i(get_global_mouse_position().x, get_global_mouse_position().y, popup.size.x, 0))
					selected_behavior_variable = child as BehaviorVariable
					popup_variable()
					
		for child in get_node("VBoxContainer/HBoxContainer/Actions/ScrollContainer/VBoxContainer").get_children():
			var rect = (child as Control).get_global_rect()
			if get_global_mouse_position().x >= rect.position.x and get_global_mouse_position().x <= rect.end.x:
				if get_global_mouse_position().y >= rect.position.y and get_global_mouse_position().y <= rect.end.y:
					popup.popup(Rect2i(get_global_mouse_position().x, get_global_mouse_position().y, popup.size.x, 0))
					selected_behavior_variable = child as BehaviorVariable
					popup_signal()

func popup_variable():
	popup.clear()
	popup.add_item("Delete Variable")
	popup.add_item("Rename Variable")
	popup.add_item("Duplicate Variable")
	popup.add_item("Make Boolean")
	popup.add_item("Make Integer")
	popup.add_item("Make Float")

func popup_signal():
	popup.clear()
	popup.add_item("Delete Signal")
	popup.add_item("Rename Signal")
	popup.add_item("Duplicate Signal")


func select_popup_option(id : int):
	if id == 0:
		var check = selected_behavior_variable.get_parent().get_parent().get_parent().name == "Variables"
		selected_behavior_variable.queue_free()
		update_variable_and_signal_nodes(check)
	if id == 1:
		var old_name = selected_behavior_variable.text
		selected_behavior_variable.get_child(0).text = old_name
		selected_behavior_variable.text = " "
		selected_behavior_variable.get_child(0).visible = true
		var check = selected_behavior_variable.get_parent().get_parent().get_parent().name == "Variables"
		update_variable_and_signal_nodes_keep_index(check, " ")
	if id == 2:
		var new_var = selected_behavior_variable.duplicate()
		if selected_behavior_variable.get_parent().get_parent().get_parent().name == "Variables":
			new_var.text = new_var.text + "_COPY"
		else:
			new_var.text = new_var.text + "_COPY"
		selected_behavior_variable.get_parent().add_child(new_var)
		var check = selected_behavior_variable.get_parent().get_parent().get_parent().name == "Variables"
		update_variable_and_signal_nodes(check)
	if id == 3:
		selected_behavior_variable.set_bool_img()
	if id == 4:
		selected_behavior_variable.set_int_img()
	if id == 5:
		selected_behavior_variable.set_flt_img()

func update_variable_and_signal_nodes(which_var_nodes):
	if which_var_nodes:
		for child in graph_edit.get_children():
			if child is BehaviorNode:
				if (child as BehaviorNode).isVariableNode:
					(graph_edit as BehaviorGraphEdit).new_var(child.get_node("OptionButton"), "null", null)
	else:
		for child in graph_edit.get_children():
			if child is BehaviorNode:
				if (child as BehaviorNode).isSignalNode:
					(graph_edit as BehaviorGraphEdit).new_sig(child.get_node("OptionButton"), "null", null)

# Keep Index to help with ordering of variables / signals in option lists
func update_variable_and_signal_nodes_keep_index(which_var_nodes, old_name):
	if which_var_nodes:
		for child in graph_edit.get_children():
			if child is BehaviorNode:
				if (child as BehaviorNode).isVariableNode:
					(graph_edit as BehaviorGraphEdit).new_var(child.get_node("OptionButton"), old_name, child)
	else:
		for child in graph_edit.get_children():
			if child is BehaviorNode:
				if (child as BehaviorNode).isSignalNode:
					(graph_edit as BehaviorGraphEdit).new_sig(child.get_node("OptionButton"), old_name, child)


func record_node_move():
	selected_nodes_that_moved = Array()
	selected_nodes_start_positions = PackedVector2Array()
	selected_nodes_end_positions = PackedVector2Array()
	
	if move_history_index < len(move_history):
		move_history.resize(move_history_index)
	
	for node in selected_nodes:
		selected_nodes_start_positions.append(node.position_offset)
		selected_nodes_that_moved.append(node)

func stop_record_node_move():
	for x in range(len(selected_nodes_that_moved)):
		if x == 0:
			undo_redo.create_action("Moved Nodes")
		else:
			undo_redo.create_action("Moved Nodes", UndoRedo.MERGE_ALL)
		undo_redo.add_do_property(selected_nodes_that_moved[x], "position_offset", selected_nodes_that_moved[x].position_offset)
		undo_redo.add_undo_property(selected_nodes_that_moved[x], "position_offset", selected_nodes_start_positions[x])
		undo_redo.commit_action()
	save_graph()

func save_graph():
	if graph_data_resource != null:
		var variables = get_node("VBoxContainer/HBoxContainer/Variables")
		var signals = get_node("VBoxContainer/HBoxContainer/Actions")
		var drop_box = get_node("VBoxContainer/HBoxContainer2/HBoxContainer/Label")
		var path = resource_path
		#print("SAVING: " + path)
		graph_data_resource.save_data(path, graph_edit, variables, signals, drop_box.gd_script)

func init_graph(graph_data: BTGraph):
	var variables = get_node("VBoxContainer/HBoxContainer/Variables")
	var signals = get_node("VBoxContainer/HBoxContainer/Actions")
	clear_graph(graph_edit, variables, signals)
	clear_undo_redo_history()
	
	var drop_box = get_node("VBoxContainer/HBoxContainer2/HBoxContainer/Label")
	if graph_data.gdscript != null:
		drop_box.gd_script = graph_data.gdscript
		drop_box.clear_btn.disabled = false
		drop_box.refresh_btn.disabled = false
		var path = (graph_data.gdscript as GDScript).resource_path
		drop_box.get_node(".").text = path.split("/")[-1]
		drop_box.fill_data(false)
	
	for node in graph_data.data:
		if node.type == 1:
			#print("VARIABLE")
			var new_var = behavior_variale.instantiate()
			variables.get_node("ScrollContainer/VBoxContainer").add_child(new_var)
			new_var.text = node.name
			if node.opt_1 == 0:
				(new_var as Button).icon = (new_var as BehaviorVariable).bool_img
				new_var.datatype = 0
			if node.opt_1 == 1:
				(new_var as Button).icon = (new_var as BehaviorVariable).int_img
				new_var.datatype = 1
			if node.opt_1 == 2:
				(new_var as Button).icon = (new_var as BehaviorVariable).flt_img
				new_var.datatype = 2
		if node.type == 2:
			#print("SINGAL")
			var new_var = behavior_variale.instantiate()
			new_var.datatype = -1
			signals.get_node("ScrollContainer/VBoxContainer").add_child(new_var)
			new_var.text = node.name
	
	var root_node_spawned = false
	for node in graph_data.data:
		if node.type == 0:
			var new_node
			if node.name == "Statement":
				new_node = statement_node.instantiate()
			if node.name == "Bool":
				new_node = bool_node.instantiate()
			if node.name == "If":
				new_node = if_node.instantiate()
			if node.name == "Sequencer":
				new_node = sequencer_node.instantiate()
			if node.name == "Action":
				new_node = action_node.instantiate()
				if graph_data.gdscript != null:
					var methods = graph_data.gdscript.new().get_method_list()
					for method in methods:
						if  method["name"].substr(0,9) == "BTAction_":
							new_node.get_node("OptionButton").add_item("Action: " + method["name"])
			if node.name == "Wait":
				new_node = wait_node.instantiate()
				if graph_data.gdscript != null:
					var sigs = graph_data.gdscript.new().get_signal_list()
					for sig in sigs:
						new_node.get_node("OptionButton").add_item("Signal: " + sig["name"])
			if node.name == "Comment":
				new_node = comment.instantiate()
			if node.name == "Variable":
				new_node = variable_node.instantiate()
				(graph_edit as BehaviorGraphEdit).new_var(new_node.get_node("OptionButton"), "null", null)
			if node.name == "Signal":
				new_node = signal_node.instantiate()
				(graph_edit as BehaviorGraphEdit).new_sig(new_node.get_node("OptionButton"), "null", null)
			if node.name == "Root" && root_node_spawned == false:
				if ref_to_root != null:
					graph_edit.add.add_child(ref_to_root)
					new_node = ref_to_root
					root_node_spawned = true
				else:
					new_node = root_node.instantiate()
					new_node.name = "RootNode"
					root_node_spawned = true
			graph_edit.add_child(new_node)
			if new_node != null:
				if new_node is BTComment:
					(new_node as BTComment).text_edit.text = node.txt
					(new_node as BTComment).previous_comment = node.txt
					(new_node as BTComment).color_picker.color = node.col
					(new_node as BTComment).font_sizes.selected = node.opt_1 
					(new_node as BTComment).self_modulate = node.col
					(new_node as BTComment).previous_color = node.col
					(new_node as BTComment).change_font_size_no_undo(node.opt_1)
					new_node.size = node.size
				if new_node is BehaviorNode:
					if (new_node as BehaviorNode).options_1 != null:
						if (new_node as BehaviorNode).options_1.item_count > node.opt_1:
							(new_node as BehaviorNode).options_1.selected = node.opt_1
							(new_node as BehaviorNode).previous_option = node.opt_1
						else:
							(new_node as BehaviorNode).options_1.selected = 0
							(new_node as BehaviorNode).previous_option = 0
						if (new_node as BehaviorNode).isBoolNode:
							if node.opt_1 == 2:
								(new_node as BehaviorNode).set_slot_color_left(3, (new_node as BehaviorNode).disabled_color)
								(new_node as BehaviorNode).get_node("Label2").self_modulate = Color(0.5, 0.5, 0.5, 0.5)
					if (new_node as BehaviorNode).options_2 != null:
						if (new_node as BehaviorNode).options_2.item_count > node.opt_2:
							(new_node as BehaviorNode).options_2.selected = node.opt_2
							(new_node as BehaviorNode).previous_option_2 = node.opt_2
						else:
							(new_node as BehaviorNode).options_2.selected = 0
							(new_node as BehaviorNode).previous_option_2 = 0
					if (new_node as BehaviorNode).text_edit != null:
						(new_node as BehaviorNode).text_edit.text = node.txt
						(new_node as BehaviorNode).previous_comment = node.txt
						(new_node as BehaviorNode).text_editability(node.opt_1)
				new_node.position_offset = node.pos
				if node.name != "Comment" && node.name != "Root":
					(new_node as BehaviorNode).loading_rid = node.rid
	
	for con in graph_data.connections:
		var has_from_node = null
		var has_to_node = null
		for child in graph_edit.get_children():
			if child is BehaviorNode:
				if child.loading_rid == con.to_node:
					has_to_node = child
				if child.loading_rid == con.from_node:
					has_from_node = child
		
		if con.to_node == "RootNode":
			has_to_node = graph_edit.get_node("RootNode")
		if con.from_node == "RootNode":
			has_from_node = graph_edit.get_node("RootNode")
		
		if has_to_node != null and has_from_node != null:
			var _e = graph_edit.connect_node(has_from_node.name, con.from_port, has_to_node.name, con.to_port)
	
	if root_node_spawned == false:
		var root = root_node.instantiate()
		graph_edit.add_child(root)
		root.position_offset = Vector2(93,91)


func clear_graph(graph_edit, variables, signals):
	graph_edit.clear_connections()
	var nodes = graph_edit.get_children()
	for node in nodes:
		if node is GraphNode:
			if node.name == "RootNode":
				graph_edit.remove_child(node)
			else:
				node.queue_free()
	nodes = variables.get_node("ScrollContainer/VBoxContainer").get_children()
	for node in nodes:
		if node is BehaviorVariable:
			node.queue_free()
	nodes = signals.get_node("ScrollContainer/VBoxContainer").get_children()
	for node in nodes:
		if node is BehaviorVariable:
			node.queue_free()

