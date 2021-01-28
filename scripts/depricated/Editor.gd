extends KinematicBody

const GRAVITY = -24.8
const MAX_SPEED = 20
const JUMP_SPEED = 10
const MAX_SLOPE_ANGLE = 40
const ACCEL = 8
const DEACCEL = 16
const RUN_SPEED = 16
const WALK_SPEED = 3

var step_time = 0

var vel = Vector3()
var hvel = Vector3()
var dir = Vector3()

var camera_mode = true
var cam
var invert_x = -1
var invert_y = -1

var always_run = true

var is_jumping = false

var speed = RUN_SPEED				# 1 step is 4 speed

var jumpscale = 0
var anim_run_interp = 0			#KEEP THIS, IT DOES THE INERTIA OF THE ANIMATIONS
var sine_time = 0

var MOUSE_SENSITIVITY = 0.1

var options_scene = preload("res://scenes/Options.tscn")
var options_node

var rng = RandomNumberGenerator.new()
var steps = []
var steps_target

var mouse_colliding = false

var playermodel = "Yaw/ussr male"

onready var step_sound = $Steps

signal paused
signal unpaused

var player_info = {
	"health": 100,
	"name": "barnyard",
	"kills": 0,
	"deaths": 0
}
	
func _ready():
	
	if Global.game_config["invert_x"]:
		invert_x *= -1
	if Global.game_config["invert_y"]:
		invert_y *= -1
		

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and !Global.is_paused:
		$Yaw/FpsCamera.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * invert_y))
		$Yaw.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * invert_x))
		$Yaw/FpsCamera.rotation_degrees.x = clamp($Yaw/FpsCamera.rotation_degrees.x, -89, 89)

func _physics_process(delta):
	
	dir = Vector3()				#keep this, it resets and prevents continuous player movement
	
	if !Global.is_paused:
			
			
		if Input.is_action_pressed("move_forward"):
			dir -= cam.basis.z							#cameras Z axis
		if Input.is_action_pressed("move_backward"):
			dir += cam.basis.z
		if Input.is_action_pressed("move_left"):
			dir -= cam.basis.x
		if Input.is_action_pressed("move_right"):
			dir += cam.basis.x
		
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		
		if !Global.is_paused and !is_instance_valid(options_node):
			
			var options_node = options_scene.instance()
			add_child(options_node)
			connect("paused", options_node, "_on_Player_paused")	#gotta have theses in processing because its a new scene everytime its spawned
			connect("unpaused", options_node, "_on_Player_unpaused")
			
			emit_signal("paused")
		else:
			emit_signal("unpaused")
			
	
	dir = dir.normalized()			#makes diagonal movement the same speed as cardinal movement
	
	hvel = vel
	
	var target = dir
	
	target *= speed
#	if joy_left.length() > 0.1:
#		target *= (joy_left.length())
#
	var accel
	if dir.dot(hvel) > 0:		#dot product: get speed, check if speed is above zero
		accel = ACCEL
	else:
		accel = DEACCEL
	
	hvel = hvel.linear_interpolate(target, accel * delta)	#the interpolation is for momentium,
	vel = hvel
	
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE), false)
