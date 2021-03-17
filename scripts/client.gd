extends Controller
class_name Client

#All the client code goes here

var options_scene = preload("res://scenes/Control/Options.tscn")
var options_node = null

signal paused
signal unpaused

func _ready():
	# Capture the mouse cursor within the window frame
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(_delta):
	# Send our input to the character. If we didn't have this system then all
	# of our player nodes would play copy-cat with each other. Trust me there's
	# a good reason for doing this
	player.cmd[0] = Input.is_action_pressed("move_forward")
	player.cmd[1] = Input.is_action_pressed("move_backward")
	player.cmd[2] = Input.is_action_pressed("move_left")
	player.cmd[3] = Input.is_action_pressed("move_right")
	player.cmd[4] = Input.is_action_pressed("move_jump")
	player.cmd[5] = Input.is_action_pressed("move_run")
	player.cmd[6] = Input.is_action_pressed("move_crouch")
	player.cmd[7] = Input.is_action_pressed("ui_flashlight")
	player.cmd[8] = Input.is_action_pressed("mouse_left")
	player.cmd[9] = Input.is_action_pressed("mouse_right")
	player.cmd[10] = Input.is_action_just_pressed("ui_use")
	player.cmd[11] = Input.is_action_pressed("ui_reload")
	
	# Escape toggles the mouse mode
	if Input.is_action_just_pressed("ui_cancel"):
		
		if !Global.is_paused and !is_instance_valid(options_node):		#keep the global.is_paused
			
			options_node = options_scene.instance()
			player.add_child(options_node)
			#options_node.set_focus_mode(Control.FOCUS_ALL)
			connect("paused", options_node, "_on_Player_paused")	#gotta have theses in processing because its a new scene everytime its spawned
			connect("unpaused", options_node, "_on_Player_unpaused")
			
			emit_signal("paused")
		else:
			emit_signal("unpaused")
			
# For type checking
func is_player():
	return true
