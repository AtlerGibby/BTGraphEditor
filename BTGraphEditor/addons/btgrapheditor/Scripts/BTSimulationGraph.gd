## The window for viewing a simulation of the BTGraph of a BTInterpreter in runtime.
extends Window
class_name BTSimulationGraph

## Toggle BTGraph Simulation.
@export var enabled : bool

## The node used to build the BTGraph in the simulation window.
var sim_node : PackedScene = load("res://addons/btgrapheditor/Components/SimNode.tscn")


var variables : Array[String]
var signals : Array[String]
var actions : Array[String]
var wait_signals : Array[String]

## Save size of window when closing it.
var old_size : Vector2i
## Array of all interpreters in the scene.
var all_interpreters : Array
## Array of all nodes in the BTGraph.
var all_nodes : Array
## The current BTGraph / BTInterpreter being simulated.
var current : BTInterpreter
## Array of all Labels on variable nodes showing the values of those variables.
var variable_node_texts : Array[Label]

## Used to check if a different interpreter is selected from the OptionButton.
var current_item : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if enabled:
		visible = true
		connect("close_requested", close_requested)
		(get_node("Button") as Button).pressed.connect(self.open_sim)
	else:
		visible = false
	
	get_all_interpreters()
	init_graph()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if len(all_interpreters) > 0 and get_node("GraphEdit").get_child_count() ==  0:
		init_graph()
	if enabled:
		if (get_node("OptionButton") as OptionButton).selected != current_item:
			current_item = (get_node("OptionButton") as OptionButton).selected
			init_graph()
		if get_node("GraphEdit").visible:
			if current != null:
				for node in all_nodes:
					var found = false
					if (current as BTInterpreter).interpeterCPP != null:
						for rid in (current as BTInterpreter).interpeterCPP.current_node_rids:
							if rid == node.loading_rid:
								found = true
								break
					else:
						for c in (current as BTInterpreter).current_nodes:
							if c.rid == node.loading_rid:
								found = true
								break
					if found:
						node.self_modulate = Color.YELLOW
					else:
						node.self_modulate = Color.GRAY
						
				if len(variable_node_texts) == len(current.variables):
					var index = 0
					for v in current.variables:
						variable_node_texts[index].text = str(current.variables[v])
						index += 1

## Gets all interpreters and populates the OptionButton with options.
func get_all_interpreters():
	var root = get_parent()
	while root.get_parent() is Node:
		root = root.get_parent()
	root = root.get_child(0)
	
	all_interpreters = interpreter_search(root)
	(get_node("GraphEdit") as GraphEdit).clear_connections()
	if len(all_interpreters) == 0:
		(get_node("OptionButton") as OptionButton).clear()
		(get_node("OptionButton") as OptionButton).add_item("No BTInterpreters Found In Scene")
	else:
		(get_node("OptionButton") as OptionButton).clear()
	for interpreter in all_interpreters:
		(get_node("OptionButton") as OptionButton).add_item(interpreter.get_parent().name + " > " + interpreter.name)
	(get_node("OptionButton") as OptionButton).selected = 0

## Adds a single interpreter to "all_interpreters" and updates the OptionButton.
func add_one_interpreter(interpreter):
	if len(all_interpreters) == 0:
		(get_node("OptionButton") as OptionButton).clear()
	all_interpreters.append(interpreter)
	(get_node("OptionButton") as OptionButton).add_item(interpreter.get_parent().name + " > " + interpreter.name)

## Recursively looks for all interpreters under the given node.
func interpreter_search(node : Node):
	var array = []
	for child in node.get_children():
		if child.is_queued_for_deletion() == false:
			if child is BTInterpreter:
				array.append(child)
			else:
				array.append_array(interpreter_search(child))
	return array

## Creates the graph in the window.
func init_graph():
	all_nodes.clear()
	
	for child in get_node("GraphEdit").get_children():
		child.queue_free()
	
	if len(all_interpreters) == 0:
		return
	
	current = all_interpreters[(get_node("OptionButton") as OptionButton).selected]
	var graph_data : Resource = current.BTResource
	var loaded_root = false
	var pink = Color(0.91,0,0.33,1)
	
	if graph_data.gdscript != null:
		var methods = current.get_parent().get_method_list()
		for method in methods:
			if  method["name"].substr(0,9) == "BTAction_":
				actions.append("Action: " + method["name"])
		var all_parent_signals = current.get_parent().get_signal_list()
		for sig in all_parent_signals:
			wait_signals.append(sig["name"])
	
	for node in graph_data.data:
		if node.type == 1:
			variables.append(node.name)
		if node.type == 2:
			signals.append(node.name)
	
	for node in graph_data.data:
		if node.type == 0:
			if node.name != "Comment":
				var new_node : BehaviorNode = sim_node.instantiate()
				get_node("GraphEdit").add_child(new_node)
				new_node.position_offset = node.pos
				new_node.title = node.name
				new_node.loading_rid = node.rid
				if node.name == "Statement" || node.name == "Bool":
					(new_node as GraphNode).set_slot(1,true,0,pink,false,0,Color.WHITE)
					(new_node as GraphNode).set_slot(3,true,0,pink,false,0,Color.WHITE)
					(new_node as GraphNode).set_slot(4,false,0,Color.WHITE,true,0,pink)
					(new_node.get_child(4) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
					if node.name == "Statement":
						new_node.get_child(1).text = "Variable 1"
						if node.opt_1 == 0:
							new_node.get_child(2).text = "Greater Than"
						if node.opt_1 == 1:
							new_node.get_child(2).text = "Less Than"
						if node.opt_1 == 2:
							new_node.get_child(2).text = "Equal To"
						new_node.get_child(3).text = "Variable 2"
						new_node.get_child(4).text = "Result"
					else:
						new_node.get_child(1).text = "Statement 1"
						new_node.get_child(3).text = "Statement 2"
						if node.opt_1 == 0:
							new_node.get_child(2).text = "AND"
						if node.opt_1 == 1:
							new_node.get_child(2).text = "OR"
						if node.opt_1 == 2:
							new_node.get_child(2).text = "NOT"
							(new_node as GraphNode).set_slot(3,false,0,Color.WHITE,false,0,Color.WHITE)
							new_node.get_child(3).text = " "
						if node.opt_1 == 3:
							new_node.get_child(2).text = "XOR"
						new_node.get_child(4).text = "Result"
				if node.name == "If":
					(new_node as GraphNode).set_slot(1,true,0,Color.WHITE,false,0,Color.WHITE)
					(new_node as GraphNode).set_slot(2,true,0,pink,false,0,Color.WHITE)
					(new_node as GraphNode).set_slot(3,false,0,Color.WHITE,true,0,Color.WHITE)
					(new_node as GraphNode).set_slot(4,false,0,Color.WHITE,true,0,Color.WHITE)
					new_node.get_child(1).text = " "
					new_node.get_child(2).text = "Bool"
					new_node.get_child(3).text = "Is True"
					new_node.get_child(4).text = "Is False"
					(new_node.get_child(3) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
					(new_node.get_child(4) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				if node.name == "Sequencer":
					(new_node as GraphNode).set_slot(1,true,0,Color.WHITE,true,0,Color.WHITE)
					new_node.get_child(2).visible = false
					new_node.get_child(3).visible = false
					new_node.get_child(4).visible = false
					if node.opt_1 == 0:
						new_node.get_child(1).text = "Top Down"
					if node.opt_1 == 1:
						new_node.get_child(1).text = "Parallel"
					if node.opt_1 == 2:
						new_node.get_child(1).text = "Random Sequence"
					if node.opt_1 == 3:
						new_node.get_child(2).text = "Totally Random"
				if node.name == "Action":
					(new_node as GraphNode).set_slot(1,true,0,Color.WHITE,false,0,Color.WHITE)
					new_node.get_child(3).visible = false
					new_node.get_child(4).visible = false
					if node.opt_1 == 0:
						new_node.get_child(1).text = "No Action"
					if node.opt_1 >= 1:
						new_node.get_child(1).text = actions[node.opt_1 - 1]
					if node.opt_2 == 0:
						new_node.get_child(2).text = "No Wait Behavior"
					if node.opt_2 == 1:
						new_node.get_child(2).text = "Wait For False Return"
					if node.opt_2 == 2:
						new_node.get_child(2).text = "Wait For True Return"
				if node.name == "Wait":
					(new_node as GraphNode).set_slot(2,true,0,Color.WHITE,false,0,Color.WHITE)
					new_node.get_child(3).visible = false
					new_node.get_child(4).visible = false
					if node.opt_1 == 0:
						new_node.get_child(1).text = "Seconds:"
						new_node.get_child(2).text = node.txt
					if node.opt_1 == 1:
						new_node.get_child(1).text = "Miliseconds:"
						new_node.get_child(2).text = node.txt
					if node.opt_1 >= 2:
						new_node.get_child(1).text = "Signal:"
						new_node.get_child(2).text = wait_signals[node.opt_1 - 2]
				if node.name == "Comment":
					pass
				if node.name == "Variable":
					(new_node as GraphNode).set_slot(1,false,0,Color.WHITE,true,0,pink)
					new_node.get_child(3).visible = false
					new_node.get_child(4).visible = false
					if node.opt_1 == 0:
						new_node.get_child(1).text = "True"
						new_node.get_child(2).text = " "
					if node.opt_1 == 1:
						new_node.get_child(1).text = "False"
						new_node.get_child(2).text = " "
					if node.opt_1 == 2:
						new_node.get_child(1).text = "Integer:"
						new_node.get_child(2).text = node.txt
					if node.opt_1 == 3:
						new_node.get_child(1).text = "Float:"
						new_node.get_child(2).text = node.txt
					if node.opt_1 >= 4:
						new_node.get_child(1).text = variables[node.opt_2] + ":"
						variable_node_texts.append(new_node.get_child(2))
				if node.name == "Signal":
					(new_node as GraphNode).set_slot(1,true,0,Color.WHITE,false,0,Color.WHITE)
					new_node.get_child(2).visible = false
					new_node.get_child(3).visible = false
					new_node.get_child(4).visible = false
					new_node.get_child(1).text = signals[node.opt_1 - 1]
				if node.name == "Root" && !loaded_root:
					new_node.name = "RootNode"
					loaded_root = true
					(new_node as GraphNode).set_slot(1,false,0,Color.WHITE,true,0,Color.WHITE)
					new_node.get_child(1).text = " "
					new_node.get_child(2).visible = false
					new_node.get_child(3).visible = false
					new_node.get_child(4).visible = false
				
				new_node.size = node.size
				all_nodes.append(new_node)
	
	for con in graph_data.connections:
		var has_from_node = null
		var has_to_node = null
		for child in get_node("GraphEdit").get_children():
			if child is BehaviorNode:
				if child.loading_rid == con.to_node:
					has_to_node = child
				if child.loading_rid == con.from_node:
					has_from_node = child
		
		if con.to_node == "RootNode":
			has_to_node = get_node("GraphEdit").get_node("RootNode")
		if con.from_node == "RootNode":
			has_from_node = get_node("GraphEdit").get_node("RootNode")
		
		if has_to_node != null and has_from_node != null:
			var _e = get_node("GraphEdit").connect_node(has_from_node.name, con.from_port, has_to_node.name, con.to_port)
	pass

## Open the BTSimulation window.
func open_sim():
	get_node("Button").visible = false
	get_node("GraphEdit").visible = true
	get_node("OptionButton").visible = true
	size = old_size

## Close the BTSimulation window.
func close_requested():
	get_node("Button").visible = true
	get_node("GraphEdit").visible = false
	get_node("OptionButton").visible = false
	old_size = size
	size = get_node("Button").size
