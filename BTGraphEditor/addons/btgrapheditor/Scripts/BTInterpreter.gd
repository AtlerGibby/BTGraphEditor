## Interprets BTGraphs for nodes in a scene.
@icon("res://addons/btgrapheditor/Icons/BTIcon.png")
extends Node
class_name BTInterpreter

## The Behavior Tree Resource to use.
@export var BTResource : Resource
## Enables or disables the BTGraph.
@export var execute_logic : bool

## Multiplied by the current time to seed the RandomNumberGenerator.
var random_seed : int = 1
## Queue for connecting callables to the signals in the signals Array for when they haven't been created yet.
var signal_wait_list : Dictionary

## Array of variables in the BTGraph.
var variables : Dictionary
## Array of signals that are emitted from the BTGraph.
var signals : Array[String]
## Array of actions called by the BTGraph.
var actions : Array[String]
## Array of signals that the BTGraph will wait on.
var wait_signals : Array[String]

## Temporary object for storing the info of a node in the BTGraph.
class BTGraphNode extends RefCounted:
	var pos : Vector2
	var name : String
	var rid : String
	var opt_1 : int
	var opt_2 : int
	var txt : String
	var to_nodes : Array[BTGraphNode]
	var from_nodes : Array[BTGraphNode]
	var to_ports : Array[int]
	var from_ports : Array[int]
	
	var is_waiting : bool
	var scene_tree_timer : SceneTreeTimer
	var wait : Array
	var wait_callable : Callable
	
	func called():
		#print("CALLED")
		wait[0] = false

## List of all branches.
var branches = Array([])
## List of all current nodes on all branches.
var current_nodes = Array([])

## List of all BTGraphNodes.
var my_bt_nodes : Array[BTGraphNode]

## The C++ interpreter, for better performance. Make sure there is a [BTInterpreterCPP] sibling node.
var interpeterCPP : BTInterpreterCPP

# Called when the node enters the scene tree for the first time.
func _ready():
	setup_bt()

## INTERNAL FUNCTION: sets up the BTInterpreter on ready.
func setup_bt():
	
	for child in get_parent().get_children():
		if child is BTInterpreterCPP:
			interpeterCPP = child
			break
	
	if get_parent().get_script() == BTResource.gdscript:
		var methods = get_parent().get_method_list()
		for method in methods:
			if  method["name"].substr(0,9) == "BTAction_":
				actions.append("Action: " + method["name"])
		var all_parent_signals = get_parent().get_signal_list()
		for sig in all_parent_signals:
			wait_signals.append(sig["name"])
	
	for node in BTResource.data:
		if node.type == 1:
			#print("VARIABLE")
			if node.opt_1 == 0:
				variables.merge({node.name: false})
			if node.opt_1 == 1:
				variables.merge({node.name: 0})
			if node.opt_1 == 2:
				variables.merge({node.name: 0.0})
		if node.type == 2:
			#print("SINGAL")
			add_user_signal(node.name)
			signals.append(node.name)
	
	for x in range(len(BTResource.data)):
		var node = BTResource.data[x]
		if node.type == 0:
			var new_node = BTGraphNode.new()
			new_node.pos = BTResource.data[x].pos
			new_node.name = BTResource.data[x].name
			new_node.rid = BTResource.data[x].rid
			new_node.opt_1 = BTResource.data[x].opt_1
			new_node.opt_2 = BTResource.data[x].opt_2
			new_node.txt = BTResource.data[x].txt
			my_bt_nodes.append(new_node)
	
	
	for con in BTResource.connections:
		var from = null
		var to = null
		var from_p = 0
		var to_p = 0
		for x in range(len(BTResource.data)):
			if BTResource.data[x].rid == con["from_node"]:
				from = my_bt_nodes[x]
				from_p = con["from_port"]
			if BTResource.data[x].rid == con["to_node"]:
				to = my_bt_nodes[x]
				to_p = con["to_port"]
		if from != null:
			from.to_nodes.append(to)
			from.to_ports.append(to_p)
		if to != null:
			to.from_nodes.append(from)
			to.from_ports.append(from_p)
	
	for node in my_bt_nodes:
		var to_sorted = top_down_sort_nodes(node.to_nodes, node.to_ports)
		var from_sorted = top_down_sort_nodes(node.from_nodes, node.from_ports)
		node.to_nodes = (to_sorted[0] as Array[BTGraphNode])
		node.to_ports = (to_sorted[1] as Array[int])
		node.from_nodes = (from_sorted[0] as Array)
		node.from_ports = (from_sorted[1] as Array)
		node.to_nodes.reverse()
		node.to_ports.reverse()
		node.from_nodes.reverse()
		node.from_ports.reverse()
	
	if interpeterCPP != null:
		
		var pos := PackedVector2Array()
		var names := PackedStringArray()
		var rids := PackedStringArray()
		var opt1 := PackedInt32Array()
		var opt2 := PackedInt32Array()
		var txt := PackedStringArray()
		var toNodes := Array()
		var fromNodes := Array()
		var toPorts := Array()
		var fromPorts := Array()
		
		for n in my_bt_nodes:
			pos.append(n.pos)
			names.append(n.name)
			rids.append(n.rid)
			opt1.append(n.opt_1)
			opt2.append(n.opt_2)
			txt.append(n.txt)
			var tn := PackedFloat32Array()
			var fn := PackedFloat32Array()
			for t in n.to_nodes:
				tn.append(my_bt_nodes.find(t))
			for f in n.from_nodes:
				fn.append(my_bt_nodes.find(f))
			toNodes.append(tn)
			fromNodes.append(fn)
			toPorts.append(n.to_ports)
			fromPorts.append(n.from_ports)
			
		interpeterCPP.setup_nodes(pos, names, rids, opt1, opt2, txt, toNodes, fromNodes, toPorts, fromPorts)
		interpeterCPP.setup(variables, signals, actions, wait_signals, my_bt_nodes, self)

## Best way to connect an external callable to a signal in the signal Array; uses the "signal_wait_list" queue.
func connect_to_signal (sig_name : String, to_this : Callable):
	signal_wait_list.merge({sig_name: to_this})

## Best way to set the "random_seed" variable.
func set_random_seed (seed):
	if interpeterCPP:
		interpeterCPP.random_seed = seed
	else:
		random_seed = seed

## INTERNAL FUNCTION: Main Loop of the BTInterpreter
func execute_bt_logic():
	if len(branches) <= 0:
		branches = Array([])
		
		for x in my_bt_nodes:
			if x.name == "Root":
				var current_branch = Array([])
				for next in x.to_nodes:
					current_branch.insert(0, next)
				branches.append(current_branch)
				current_nodes.append(current_branch[0])
				break
	
	var rng = RandomNumberGenerator.new()
	var time_dict = Time.get_datetime_dict_from_system ()
	rng.seed = int(time_dict["year"]) * int(time_dict["day"]) * int(time_dict["hour"]) * int(time_dict["minute"]) * int(time_dict["second"]) * random_seed
	
	if len(branches) > 0:
		
		for potential_new_nodes in branches: #Each node in each parallel branch
			
			if len(potential_new_nodes) == 0:
				current_nodes.remove_at(branches.find(potential_new_nodes))
				branches.erase(potential_new_nodes)
				continue
			
			#print("LOOP: " + potential_new_nodes[0].name)
			var current = potential_new_nodes[0]
			current_nodes[branches.find(potential_new_nodes)] = current
			
			if current.name == "Action":
				if current.opt_1 > 0: #Action Selected
					if current.opt_2 > 0: #Has Wait Behavior
						if current.is_waiting == true:
							get_parent().call((actions[current.opt_1-1]).substr(8), current.wait)
							if current.opt_2 == 1 && current.wait[0] == true:
								continue
							if current.opt_2 == 2 && current.wait[0] == false:
								continue
							current.is_waiting = false
							current.wait.clear()
						else:
							current.is_waiting = true
							#var bt_wait = BTWait.new()
							current.wait = Array()
							if current.opt_2 == 1:
								current.wait.append(true)
							else:
								current.wait.append(false)
							get_parent().call((actions[current.opt_1-1]).substr(8), current.wait)
							continue
					else:
						get_parent().call((actions[current.opt_1-1]).substr(8), null)
			
			if current.name == "Signal":
				emit_signal(signals[current.opt_1-1])
			
			if current.name == "Wait":
				if current.opt_1 <= 1: #Wait on time
					if current.is_waiting == true:
						if current.scene_tree_timer.time_left > 0:
							continue
						else:
							current.is_waiting = false
							current.scene_tree_timer = null
					else:
						current.is_waiting = true
						var wait_time = float(current.txt)
						if wait_time > 0:
							if current.opt_1 == 1:
								wait_time /= 1000
							current.scene_tree_timer = get_tree().create_timer(wait_time)
							continue
				else: #Wait on Signal
					if current.is_waiting == true:
						if current.wait[0] == true:
							continue
						current.is_waiting = false
						current.wait.clear()
						get_parent().disconnect(wait_signals[current.opt_1-2], current.wait_callable)
						current.wait_callable = Callable()
						#print("BREAK")
					else:
						current.is_waiting = true
						#var bt_wait = BTWait.new()
						current.wait = Array()
						current.wait.append(true)
						var my_call = Callable(current, "called")
						current.wait_callable = my_call
						get_parent().connect(wait_signals[current.opt_1-2], current.wait_callable)
						#print(current.opt_1-2)
						#print("SIGNAL WAIT")
						continue
			
			if current.name == "Sequencer":

				if current.opt_1 == 1: #Parallel
					for next in current.to_nodes:
						var current_branch = Array([])
						current_branch.insert(0, next)
						branches.append(current_branch)
						current_nodes.append(current_branch[0])
				
				if current.opt_1 == 2: #Random
					for next in current.to_nodes:
						var ran = rng.randi_range(0, len(current.to_nodes) - 1)
						while potential_new_nodes.has(current.to_nodes[ran]):
							if ran == len(current.to_nodes) - 1:
								ran = 0
							else:
								ran += 1
						potential_new_nodes.insert(0, current.to_nodes[ran])
				
				if current.opt_1 == 3: #TotallyRandom
					for next in current.to_nodes:
						var ran = rng.randi_range(0, len(current.to_nodes) - 1)
						potential_new_nodes.insert(0, current.to_nodes[ran])
				
				if current.opt_1 == 0: #TopDown
					for next in current.to_nodes:
						potential_new_nodes.insert(0, next)
			
			if current.name == "If":
				var bool_input = null
				var true_output = Array([])
				var false_output = Array([])
				
				for x in range(len(current.to_ports)):
					if current.to_nodes[x].from_ports[0] == 1:
						true_output.append(current.to_nodes[x])
					else:
						false_output.append(current.to_nodes[x])
				
				if len(current.from_ports) > 1:
					
					if current.from_ports[0] == 1:
						bool_input = current.from_nodes[0]
					else:
						bool_input = current.from_nodes[1]
					
					var bool_val = evaluate_bool(bool_input, current)
					if bool_val == true:
						for next in true_output:
							potential_new_nodes.insert(0, next)
					else:
						for next in false_output:
							potential_new_nodes.insert(0, next)
				else:
					for next in false_output:
						potential_new_nodes.insert(0, next)
			
			potential_new_nodes.erase(current)
			 #next node in potential_new_nodes
			
			#if len(potential_new_nodes) == 0:
				#print("BRANCH END")
			#	current_nodes.remove_at(branches.find(potential_new_nodes))
			#	branches.erase(potential_new_nodes)
	

## INTERNAL FUNCTION: Recursively evaluates an "If" node's "children" nodes.
func evaluate_bool(node, from_node):
	var return_type_is_bool = true
	if from_node.name == "Statement":
		return_type_is_bool = false
	
	if node == null:
		if return_type_is_bool:
			return false
		else:
			return 0
	
	if node.name == "Variable":
		if node.opt_1 == 0: #true
			if return_type_is_bool:
				return true
			else:
				return 1
		if node.opt_1 == 1: #false
			if return_type_is_bool:
				return false
			else:
				return 0
		if node.opt_1 == 2: #int
			var txt_num = int(node.txt)
			if return_type_is_bool:
				if txt_num > 0:
					return true
				else:
					return false
			else:
				return txt_num
		if node.opt_1 == 3: #float
			var txt_num = float(node.txt)
			if return_type_is_bool:
				if txt_num > 0:
					return true
				else:
					return false
			else:
				return txt_num
		if node.opt_1 >= 4: #Variable from left panel
			var the_var = variables[variables.keys()[node.opt_1-4]]
			if the_var is float || the_var is int:
				if return_type_is_bool:
					if the_var > 0:
						return true
					else:
						return false
				else:
					return the_var
			if the_var is bool:
				if return_type_is_bool:
					return the_var
				else:
					if the_var:
						return 1
					else:
						return 0
	else: #Keep searching tree leftward
		var from_node_top = null
		var from_node_bottom = null
		
		if len(node.from_ports) > 0:
			if node.from_ports[0] == 0:
				from_node_top = node.from_nodes[0]
				if len(node.from_nodes) > 1:
					from_node_bottom = node.from_nodes[1]
			else:
				from_node_bottom = node.from_nodes[0]
				if len(node.from_nodes) > 1:
					from_node_top = node.from_nodes[1]
		
		if node.name == "Bool":
			if node.opt_1 == 0: #AND
				return evaluate_bool(from_node_top, node) and evaluate_bool(from_node_bottom, node)
			if node.opt_1 == 1: #OR
				return evaluate_bool(from_node_top, node) or evaluate_bool(from_node_bottom, node)
			if node.opt_1 == 2: #NOT
				return not evaluate_bool(from_node_top, node)
			if node.opt_1 == 3: #XOR
				return not (evaluate_bool(from_node_top, node) == evaluate_bool(from_node_bottom, node))
		if node.name == "Statement":
			if node.opt_1 == 0: #GreaterThan
				return evaluate_bool(from_node_top, node) > evaluate_bool(from_node_bottom, node)
			if node.opt_1 == 1: #LessThan
				return evaluate_bool(from_node_top, node) < evaluate_bool(from_node_bottom, node)
			if node.opt_1 == 2: #EquallTo
				return evaluate_bool(from_node_top, node) == evaluate_bool(from_node_bottom, node)
	
	return false

## INTERNAL FUNCTION: Sorts list of nodes / ports by there Y-position value in top down order.
func top_down_sort_nodes(node_array, port_array):
	
	var new_node_array : Array[BTGraphNode] = []
	var new_port_array : Array[int] = []
	
	var top_node = null
	var top_node_port = 0
	
	while len(node_array) > len(new_node_array):
		for x in range(len(node_array)):
			if new_node_array.has(node_array[x]) == false:
				if top_node == null:
					top_node = node_array[x]
					top_node_port = port_array[x]
				elif node_array[x].pos.y < top_node.pos.y:
					top_node = node_array[x]
					top_node_port = port_array[x]
		new_node_array.append(top_node)
		new_port_array.append(top_node_port)
		top_node = null
	
	return [new_node_array, new_port_array]

## Best way to set a variable in the variable Array.
func edit_variable(var_name, value):
	if variables[var_name] is bool:
		variables[var_name] = (value as bool)
	if variables[var_name] is int:
		variables[var_name] = (value as int)
	if variables[var_name] is float:
		variables[var_name] = (value as float)
	if interpeterCPP:
		interpeterCPP.edit_variable(var_name, value)


## Stop all branches / reset behavior tree.
func stop_all_branches():
	if interpeterCPP:
		interpeterCPP.stop_all_branches()
	else:
		skip_all_current_nodes()
		branches.clear()

## Stop the current branch.
func stop_a_branch(which_branch : int):
	if interpeterCPP:
		interpeterCPP.stop_a_branch(which_branch)
	else:
		skip_current_node(which_branch)
		branches.remove_at(which_branch)

## Skip all nodes that are waiting.
func skip_all_current_nodes():
	if interpeterCPP:
		interpeterCPP.skip_all_current_nodes()
	else:
		for x in range(len(current_nodes)):
			skip_current_node(x)

## Skip the current node on a branch that is waiting.
func skip_current_node(which_branch : int):
	if interpeterCPP:
		interpeterCPP.skip_current_node(which_branch)
	else:
		if len(current_nodes) > which_branch:
			current_nodes[which_branch].is_waiting = false
			current_nodes[which_branch].wait = null
			current_nodes[which_branch].scene_tree_timer = null
			if current_nodes[which_branch].wait_callable.is_null() == false:
				get_parent().disconnect(wait_signals[current_nodes[which_branch].opt_1-2], current_nodes[which_branch].wait_callable)
				current_nodes[which_branch].wait_callable = Callable()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if execute_logic:
		if interpeterCPP != null:
			interpeterCPP.execute_logic()
		else:
			execute_bt_logic()
	
	if signal_wait_list.is_empty() == false:
		for key in signal_wait_list.keys():
			for sig in signals:
				if sig == key:
					connect(sig, signal_wait_list[key])
					break
		signal_wait_list.clear()
			
