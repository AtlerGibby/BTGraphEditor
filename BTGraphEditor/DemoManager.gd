extends Camera3D

@export var red_guy : PackedScene
@export var blue_guy : PackedScene

var rng : RandomNumberGenerator
var all_guys : Array
var sim : BTSimulationGraph
var bool_test = false

# Called when the node enters the scene tree for the first time.
func _ready():
	rng = RandomNumberGenerator.new()
	var time_dict = Time.get_datetime_dict_from_system ()
	rng.seed = int(time_dict["year"]) * int(time_dict["day"]) * int(time_dict["hour"]) * int(time_dict["minute"]) * int(time_dict["second"])
	
	for child in get_parent().get_children():
		if child is CharacterBody3D:
			all_guys.append(child)
		if child is BTSimulationGraph:
			sim = child
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_R:
				print("RED GUY SPAWN")
				spawn_red_guy()
			if event.keycode == KEY_B:
				print("BLUE GUY SPAWN")
				spawn_blue_guy()
			if event.keycode == KEY_E:
				for guy in all_guys:
					guy.npc_test_signal.emit()
				print("Get Moving!")
			if event.keycode == KEY_T:
				bool_test = !bool_test
				for guy in all_guys:
					guy.toggle_bool_test(bool_test)
				print("Toggle Bool Test To: " + str(bool_test))
			if event.keycode == KEY_Q:
				for guy in all_guys:
					guy.destroy()
				all_guys.clear()
				if sim != null:
					sim.get_all_interpreters()
					sim.init_graph()
				print("Destroy!")


func spawn_red_guy():
	var spawn = red_guy.instantiate()
	get_parent().add_child(spawn)
	spawn.position = Vector3(rng.randf() * 30 - 15, 1, rng.randf() * 30 - 15)
	for guy in all_guys:
		guy.red_team.append(spawn)
	all_guys.append(spawn)
	if sim != null:
		sim.add_one_interpreter(spawn.get_node("BTInterpreter"))
	pass

func spawn_blue_guy():
	var spawn = blue_guy.instantiate()
	get_parent().add_child(spawn)
	spawn.position = Vector3(rng.randf() * 30 - 15, 1, rng.randf() * 30 - 15)
	for guy in all_guys:
		guy.blue_team.append(spawn)
	all_guys.append(spawn)
	if sim != null:
		sim.add_one_interpreter(spawn.get_node("BTInterpreter"))
	pass
