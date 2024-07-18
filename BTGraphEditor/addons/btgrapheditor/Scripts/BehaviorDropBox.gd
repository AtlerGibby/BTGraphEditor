@tool
extends Control

var clear_btn : Button
var refresh_btn : Button
var gd_script : GDScript

signal whatwhat
signal whatttt

# Called when the node enters the scene tree for the first time.
func _ready():
	refresh_btn = get_parent().get_node("Button")
	clear_btn = get_parent().get_node("Button2")
	if gd_script == null:
		clear_btn.disabled = true
		refresh_btn.disabled = true
		
	clear_btn.pressed.connect(self.clear)
	refresh_btn.pressed.connect(self.refresh)
	pass # Replace with function body.

func refresh ():
	fill_data(true)

func clear ():
	clear_btn.disabled = true
	refresh_btn.disabled = true
	get_node(".").text = " Drag GDScript Here... "
	for child in get_parent().get_parent().get_parent().get_node("HBoxContainer/GraphEdit").get_children():
		if child is GraphNode:
			if child.title == "Wait":
				(child.get_node("OptionButton") as OptionButton).clear()
				(child.get_node("OptionButton") as OptionButton).add_item("Time: Seconds")
				(child.get_node("OptionButton") as OptionButton).add_item("Time: Miliseconds")
	
	for child in get_parent().get_parent().get_parent().get_node("HBoxContainer/GraphEdit").get_children():
		if child is GraphNode:
			if child.title == "Action":
				(child.get_node("OptionButton") as OptionButton).clear()
				(child.get_node("OptionButton") as OptionButton).add_item(" ")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _can_drop_data(position, data):
	#print("TESTSTS")
	if typeof(data) == TYPE_DICTIONARY:
		if data["type"] == "files":
			if data["files"][0].substr(len(data["files"][0]) - 3 , len(data["files"][0])) == ".gd":
				#print("YA")
				return true
	return false #typeof(data) == TYPE_DICTIONARY and data.has("expected")

## This is a test
func BTAction_test():
	print("TESTING")

## This is a test2
#func BTAction_test2():
#	print("TESTING 2")

func _drop_data(at_position, data):
	clear_btn.disabled = false
	refresh_btn.disabled = false
	var path = data["files"][0]
	get_node(".").text = path.split("/")[-1]
	gd_script = load(path)
	fill_data(false)

func fill_data(save_after):
	var signals = gd_script.new().get_signal_list()
	for child in get_parent().get_parent().get_parent().get_node("HBoxContainer/GraphEdit").get_children():
		if child is GraphNode:
			if child.title == "Wait":
				var old_id = (child.get_node("OptionButton") as OptionButton).get_selected_id()
				var old_name = (child.get_node("OptionButton") as OptionButton).get_item_text(old_id)
				var new_id = 1
				(child.get_node("OptionButton") as OptionButton).clear()
				(child.get_node("OptionButton") as OptionButton).add_item("Time: Seconds")
				(child.get_node("OptionButton") as OptionButton).add_item("Time: Miliseconds")
				var found_old = false
				for sig in signals:
					(child.get_node("OptionButton") as OptionButton).add_item("Signal: " + sig["name"])
					new_id += 1
					if ("Signal: " + sig["name"]) == old_name:
						(child.get_node("OptionButton") as OptionButton).select(new_id)
						found_old = true
				if found_old == false:
					(child.get_node("OptionButton") as OptionButton).select(0)
	
	var methods = gd_script.new().get_method_list()
	for child in get_parent().get_parent().get_parent().get_node("HBoxContainer/GraphEdit").get_children():
		if child is GraphNode:
			if child.title == "Action":
				var old_id = (child.get_node("OptionButton") as OptionButton).get_selected_id()
				var old_name = (child.get_node("OptionButton") as OptionButton).get_item_text(old_id)
				var new_id = 0
				(child.get_node("OptionButton") as OptionButton).clear()
				(child.get_node("OptionButton") as OptionButton).add_item(" ")
				var found_old = false
				for method in methods:
					if  method["name"].substr(0,9) == "BTAction_":
						(child.get_node("OptionButton") as OptionButton).add_item("Action: " + method["name"])
						new_id += 1
						if ("Action: " + method["name"]) == old_name:
							(child.get_node("OptionButton") as OptionButton).select(new_id)
							found_old = true
				if found_old == false:
					(child.get_node("OptionButton") as OptionButton).select(0)
	
	if get_parent().get_parent().get_parent().get_parent() is BTGraphDock and save_after:
		get_parent().get_parent().get_parent().get_parent().save_graph()
