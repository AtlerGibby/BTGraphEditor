## Stores a BTGraph to be used by [BTInterpreter].
@tool
@icon("res://addons/btgrapheditor/Icons/BTResIcon.png")
extends Resource
class_name BTGraph

## List of connections between nodes.
@export var connections: Array
## List of node data.
@export var data: Array
## The GDScript connected to this BTGraph (Should be the parent node of the BTInterpreter).
@export var gdscript: GDScript

func save_data(file_name, graph_edit, variables, signals, script):
	
	gdscript = script
	connections.clear()
	
	for con in graph_edit.get_connection_list():
		var from_node = graph_edit.get_node(NodePath(con.from_node)).name
		var to_node = graph_edit.get_node(NodePath(con.to_node)).name
		connections.append({"from_node": from_node, "from_port": con.from_port, "to_node": to_node, "to_port": con.to_port})
	data.clear()
	
	for node in graph_edit.get_children():
		if node is GraphNode:
			var node_data = BTData.new()
			node_data.name = node.title
			node_data.type = 0
			node_data.pos = node.position_offset
			node_data.size = node.size
			#print(node_data.size)
			node_data.rid = node.name
			if node is BTComment:
				node_data.txt = (node as BTComment).text_edit.text
				node_data.col = (node as BTComment).color_picker.color
				node_data.opt_1 = (node as BTComment).font_sizes.selected
			if node is BehaviorNode:
				if (node as BehaviorNode).options_1 != null:
					node_data.opt_1 = (node as BehaviorNode).options_1.selected
				if (node as BehaviorNode).options_2 != null:
					node_data.opt_2 = (node as BehaviorNode).options_2.selected
				if (node as BehaviorNode).text_edit != null:
					node_data.txt = (node as BehaviorNode).text_edit.text
			data.append(node_data)
	for node in variables.get_node("ScrollContainer/VBoxContainer").get_children():
		if node is BehaviorVariable:
			var node_data = BTData.new()
			node_data.name = node.text
			node_data.type = 1
			node_data.opt_1 = node.datatype
			data.append(node_data)
	for node in signals.get_node("ScrollContainer/VBoxContainer").get_children():
		if node is BehaviorVariable:
			var node_data = BTData.new()
			node_data.name = node.text
			node_data.type = 2
			node_data.opt_1 = node.datatype
			data.append(node_data)

	if ResourceSaver.save(self, file_name) == OK:
		print("saved")
	else:
		print("Error saving graph_data")

func validate_resource(file_name):
	if ResourceLoader.exists(file_name):
		var graph_data = ResourceLoader.load(file_name).duplicate(true)
		if graph_data is BTGraph:
			return true
		else:
			return false
	else:
		return false


func load_data(file_name):
	var graph_data = ResourceLoader.load(file_name)
	if (graph_data.gdscript as GDScript) != null:
		gdscript = graph_data.gdscript
	connections = graph_data.connections
	data = graph_data.data
