extends CharacterBody3D

#const SPEED = 5.0
#const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var point_a : Node3D
var point_b : Node3D
var point_c : Node3D

var bt_interpreter : BTInterpreter

enum team {NO_TEAM, RED, BLUE}
@export var my_team : team

var blue_team : Array
var red_team : Array
var stop : bool = false

signal npc_test_signal

# Called when the node enters the scene tree for the first time.
func _ready():
	bt_interpreter = get_node("BTInterpreter")
	(bt_interpreter as BTInterpreter).connect_to_signal("SignalTest", self.callable_test)
	(bt_interpreter as BTInterpreter).set_random_seed((position.x + 1) * (position.y + 1))
	get_all_info()

func callable_test ():
	print("Test Signal...")


func get_all_info ():
	for child in get_parent().get_children():
		if child.name == "PointA":
			point_a = child
		if child.name == "PointB":
			point_b = child
		if child.name == "PointC":
			point_c = child
		if child is CharacterBody3D and child != self:
			if child.my_team == team.RED:
				red_team.append(child)
			if child.my_team == team.BLUE:
				blue_team.append(child)

func get_closest_opponent ():
	var opponent = null
	if my_team == team.RED:
		opponent = get_closest_npc(team.BLUE)
	if my_team == team.BLUE:
		opponent = get_closest_npc(team.RED)
	return opponent

func get_closest_teammate ():
	var teammate = null
	if my_team == team.RED:
		teammate = get_closest_npc(team.RED)
	if my_team == team.BLUE:
		teammate = get_closest_npc(team.BLUE)
	return teammate

func get_closest_npc (of_team : int):
	var closest_distance = 99999
	var closest_npc = null
	if of_team == team.RED:
		for npc in red_team:
			if npc.position.distance_to(self.position) < closest_distance:
				closest_npc = npc
				closest_distance = npc.position.distance_to(self.position)
	if of_team == team.BLUE:
		for npc in blue_team:
			if npc.position.distance_to(self.position) < closest_distance:
				closest_npc = npc
				closest_distance = npc.position.distance_to(self.position)
	return closest_npc

func toggle_bool_test(value):
	(bt_interpreter as BTInterpreter).edit_variable("BoolTest", value)

func destroy():
	queue_free()

func BTAction_False_Test (_bt_wait : Array):
	print("Test BTAction")

func BTAction_Test (_bt_wait : Array):
	pass

func BTAction_Go_To_A (bt_wait : Array):
	velocity = position.direction_to(point_a.position) * 5 
	if bt_wait:
		if position.distance_to(point_a.position) < 2:
			velocity = Vector3.ZERO
			bt_wait[0] = true
			print("Got To Point A")
			stop = true
		else:
			bt_wait[0] = false
			stop = false

func BTAction_Go_To_B (bt_wait : Array):
	velocity = position.direction_to(point_b.position) * 5 
	if bt_wait:
		if position.distance_to(point_b.position) < 2:
			velocity = Vector3.ZERO
			bt_wait[0] = true
			print("Got To Point B")
			stop = true
		else:
			bt_wait[0] = false
			stop = false

func BTAction_Go_To_C (bt_wait : Array):
	velocity = position.direction_to(point_c.position) * 5 
	if bt_wait:
		if position.distance_to(point_c.position) < 2:
			velocity = Vector3.ZERO
			bt_wait[0] = true
			print("Got To Point C")
			stop = true
		else:
			bt_wait[0] = false
			stop = false

#var bbbb = false
func _physics_process(_delta):
	
	var too_close_opponent = false
	var too_close_teammate = false
	if stop:
		var co = get_closest_opponent()
		if co != null:
			if co.position.distance_to(position) < 3:
				too_close_opponent = true
				velocity = position.direction_to(co.position) * -5 
			else:
				too_close_opponent = false
		var ctm = get_closest_teammate()
		if ctm != null:
			if ctm.position.distance_to(position) < 1:
				too_close_teammate = true
				velocity = position.direction_to(ctm.position) * -5 
			else:
				too_close_teammate = false
		if too_close_opponent == false and too_close_teammate == false:
			velocity = Vector3.ZERO
	if position.y != 1:
		position.y = 1
		
	#if bbbb == false:
		#if (bt_interpreter as BTInterpreter).signals.size() > 0:
			#(bt_interpreter as BTInterpreter).connect("SignalTest", self.callable_test)
			#bbbb = true
			#print("ALL SIGNALS")
			#for s in (bt_interpreter as BTInterpreter).signals:
			#	print(s);
		
	# Add the gravity.
	#if not is_on_floor():
	#	velocity.y -= gravity * delta

	# Handle Jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction:
	#	velocity.x = direction.x * SPEED
	#	velocity.z = direction.z * SPEED
	#else:
	#	velocity.x = move_toward(velocity.x, 0, SPEED)
	#	velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
