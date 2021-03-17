extends KinematicBody
class_name Player

var GRAVITY = -24.8
const MAX_SPEED = 20
const JUMP_SPEED = 10
const MAX_SLOPE_ANGLE = 65
const ACCEL = 8
const DEACCEL = 16
const RUN_SPEED = 12
const WALK_SPEED = 3

#our main player data dictionary, this gets set to a template player dictionary at
#init(), which is called first thing at _ready()
export var player_info = {
	"health": 100,
	"name": "placeholder",
	"kills": 0,
	"deaths": 0,
}

export var vel = Vector3()
export var dir = Vector3()
var hvel = Vector3()
#if we're either a player or a bot
var is_player = true

export var camera_mode = true
var cam = null
export var invert_x = -1
export var invert_y = -1
export var noclip = false
export var interp = true
export var interp_scale = 50

var inertia = 0.1
var speed = 8

var always_run = true
var step_time = 0

var rng = Global.rng

var is_dead = false
var is_jumping = false
var is_inwater = false

var mouse_colliding = false
var steps_target

var has_hud = false

var flashlight = false
var is_crouching = false

onready var step_sound = $Steps
onready var camera = $Camera
onready var weapon = $Camera/Weapon
onready var playermodel = $AnimController/ussr_male

#arrays of paths to appropriate sounds that we can play
onready var steps = Global.files_in_dir("res://sounds/player/step/", ".wav")
onready var pain_sounds = Global.files_in_dir("res://sounds/player/pain/", ".wav")

var spawn_point = null
var is_invul = false

#multiplayer data commands, to send forth over the network to tell clients how to
#move our player node
enum Command {FORWARD, BACKWARD, LEFT, RIGHT, JUMP, RUN, CROUCH, FLASHLIGHT, 
	PRIMARY, SECONDARY, USE, RELOAD}
var cmd = [false, false, false, false, false, false, false, false, false, false,
	false, false]

#TODO maybe make the player health functions into signals?
#signal damaged
#signal died
#signal respawned

#parts of this might be transfered over to lobby.gd
func init():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#if we're a player, make our name to our config
	if is_player:
		player_info["name"] = Global.game_config["player_name"]
	#if not, we're a bot and we'll have our node name, which should be "bot"
	else:
		player_info["name"] = name
		
	speed = RUN_SPEED
	#add our initial player info, under the node name (which is our network ID), to the server list
	network.rpc("send_player_data", name, player_info)
	network.rpc("console_msg", "Player " + player_info["name"] + " connected to server.")
	
func death():
	is_dead = true
	
	Global.is_paused = true
	print(player_info["name"] + " died!")
	
	player_info["deaths"] += 1
	$RespawnTimer.start()
	$PlayerCollision.disabled = true
	
	weapon.remove_all_weapons()
	
	#playermodel.get_node("Armature/Skeleton").physical_bones_start_simulation()
	
func respawn():
	
	#request the spawn point controller to find us a spawn
	var spawn = $SpawnPointController.choose_spawn()
	if spawn != null:
		transform = spawn
	else:
		print("cant find spawn points")
	
	self.show()
	$PlayerCollision.disabled = false
	
	#playermodel.get_node("Armature/Skeleton").physical_bones_stop_simulation()
	
	#print(player_info["name"] + " respawned at: " + str(transform.origin))
	$Hud.respawn()
	
	player_info["health"] = 100
	Global.is_paused = false
	
	is_dead = false
	is_invul = true
	
	if player_info["deaths"] > 0:
		$AnimController/ussr_male/Armature/Skeleton/USSR_Male.material_override = load("res://resources/SpatialMaterial/ghost.tres")
	
	$InvulTimer.start()
	
func damage(amount):
	if !is_dead and !is_invul:
		player_info["health"] -= amount
		$Hud.pain()
			
		$AnimController.hurt = 1
		Global.play_rand($Pain, pain_sounds)
		
		
remotesync func bullet_hit(damage, from, bullet_hit_pos, _force_multiplier):			#handles how bullets push the prop
	var direction_vect = global_transform.origin - bullet_hit_pos
	direction_vect = direction_vect.normalized()
	damage(damage)
	
	from = get_tree().get_rpc_sender_id()
	var from_str = str(from)
	
	#if we got killed handle the score
	if player_info["health"] <= 0 and !is_dead:
		
		#If our killer is a player
		if from_str in network.player_list:
			network.rpc("console_msg", player_info["name"] + " was killed by " + 
			network.player_list[from_str]["name"])
			$Hud/VBoxContainer/ChatBox.text += "\n" + "You got killed by " + network.player_list[from]["name"]
			
			rpc_id(from, "give_kill")
			
remote func give_kill():
	player_info["kills"] += 1


func _ready():
	Console.connect_node(self)
	init()
	
	#give our weapon node this node path
	weapon.player_node = self
	
	if Global.game_config["invert_x"]:
		invert_x *= -1
	if Global.game_config["invert_y"]:
		invert_y *= -1
	
	#If we're not master, hide our hud. If we didn't check for this, we would
	#have multiple overlapping huds for each player connected
	if !is_network_master() or !is_player:
		$Hud.hide()
		$Camera.hide()
		weapon.get_node("ViewportContainer").hide()
	
	#we call respawn in first spawn, since it sets up random spawning and death
	#state values for us
	respawn()

func _input(event):
	#FPS mouse-to-camera code
	if (event is InputEventMouseMotion and 
	Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and 
	!Global.is_paused and is_network_master() and is_player):
		camera.rotate_x(deg2rad(event.relative.y * 
		Global.game_config["mouse_sensitivity"] * invert_y))
		
		self.rotate_y(deg2rad(event.relative.x * 
		Global.game_config["mouse_sensitivity"] * invert_x))
		
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -89, 89)

func _physics_process(delta):
	
	
#	var joy_left = Vector2(Input.get_joy_axis(0, JOY_AXIS_0), Input.get_joy_axis(0, JOY_AXIS_1))
#	var joy_right = Vector2(Input.get_joy_axis(0, JOY_AXIS_2), Input.get_joy_axis(0, JOY_AXIS_3))
#
#	if(joy_left.length() < 0.1):
#		joy_left = Vector2(0, 0)
#	if(joy_right.length() < 0.1):
#		joy_right = Vector2(0, 0)
	
	#Cast a ray to where the mouse is pointing and get the position of it
	
	dir = Vector3()			#keep this, it resets and prevents continuous player movement
	
	if !Global.is_paused and !is_dead and is_network_master():
		
		if camera_mode and is_inside_tree():					#FPS
			cam = camera.get_global_transform()
			
		if cmd[Command.FORWARD]:
			dir -= cam.basis.z							#cameras Z axis
		if cmd[Command.BACKWARD]:
			dir += cam.basis.z
		if cmd[Command.LEFT]:
			dir -= cam.basis.x
		if cmd[Command.RIGHT]:
			dir += cam.basis.x
			
		if cmd[Command.JUMP] and (is_on_floor() or is_inwater or noclip):
			vel.y = JUMP_SPEED
		if Input.is_action_just_released("move_jump") and noclip:
			vel.y = 0
				
		if cmd[Command.CROUCH]:
			if is_inwater or noclip:
				vel.y = JUMP_SPEED * -1
			elif !is_crouching and !noclip:
				$AnimationPlayer.play("crouch")
				speed *= 0.5
				is_crouching = true
				$StepTimer.wait_time = 0.8
		if Input.is_action_just_released("move_crouch"):
			if noclip:
				vel.y = 0
			else:
				$AnimationPlayer.play_backwards("crouch")
				speed /= 0.5
				is_crouching = false
				$StepTimer.wait_time = 0.3
				
		if cmd[Command.FLASHLIGHT] and !flashlight:
			$FlashlightToggle.play()
			camera.get_node("Flashlight").visible = !(camera.get_node("Flashlight").visible)
			flashlight = true
			
		if Input.is_action_just_released("ui_flashlight"):
			flashlight = false
			
			
		if Input.is_action_pressed("ui_left"):
			rotate_y(4 * delta)
		if Input.is_action_pressed("ui_right"):
			rotate_y(-4 * delta)
			
	#input code ends here
	
	if !noclip and !is_dead:
		vel.y += GRAVITY * delta			#apply gravity
	
	hvel = vel
	if !is_inwater:
		hvel.y = 0
		dir.y = 0
		
	dir = dir.normalized()			#makes diagonal movement the same speed as cardinal movement
	
	var target = dir
	target *= speed

	var accel
	if dir.dot(hvel) > 0:		#dot product: get speed, check if speed is above zero
		
		if $StepTimer.is_stopped() and is_on_floor():
			$StepTimer.start()
		
		accel = ACCEL
		is_invul = false
	else:
		if !$StepTimer.is_stopped() and step_sound.get_playback_position() == 0.0:
			$StepTimer.stop()
			step_sound.stop()
			
		accel = DEACCEL
	
	#Apply our horizontal velocity to our combined velocity variable
	hvel = hvel.linear_interpolate(target, accel * delta)	#the interpolation is for momentium,
	vel.x = hvel.x											#we would just do hvel = target
	if is_inwater:
		vel.y = hvel.y
	vel.z = hvel.z
	
	#apply the velocity to our player
	vel = move_and_slide(vel, Vector3.UP, false, 4, deg2rad(MAX_SLOPE_ANGLE), false)
	
	#kill ourselves if we go too far down (poetic!)
	if transform.origin.y < -200 and !noclip:
		damage(player_info["health"])
		
	if !is_invul:
		$AnimController/ussr_male/Armature/Skeleton/USSR_Male.material_override = null
	
	for index in get_slide_count():				#player collision detection
		var collision = get_slide_collision(index)	
		#this pushes physics objects
		if collision.collider is RigidBody:
			collision.collider.apply_central_impulse(-collision.normal * inertia / 
			-collision.collider.weight)	#apply push force
			
			
	#check if we have less or equal to zero health, if so, die
	if player_info["health"] <= 0:
		if !is_dead:	#one shot
			death()
		else:			#updating
			$Hud.death(str(int($RespawnTimer.time_left)))
			
	elif player_info["health"] > 100:
		player_info["health"] = 100
	
	#NETWORK CODE
	
	# Update the position and rotation over network
	# If this character is controlled by the actual player - send it's position and rotation
	if $controller.has_method("is_player"):
		# And only transmit, if the characters node has more than 1 player
		if get_parent().get_child_count() > 1:
			
			#This sends all the player info of every player node
			network.rpc_unreliable("send_player_data", name, player_info)
			# RPC unreliable is faster but doesn't verify whether data has arrived or is intact
			rpc_unreliable("network_update", translation, rotation, delta * interp_scale)
			
			#Transmit our animation data
			var a = $AnimController
			a.rpc_unreliable("network_update", a.anim_strafe_interp, 
			a.anim_strafe_dir_interp, a.jumpscale, a.anim_run_interp, a.tilt, a.hurt)
			
		#Our client specific code
		camera.make_current()

# To update data both on a server and clients "sync" is used
remotesync func network_update(new_translation, new_rotation, delta):
	if interp:
		translation = translation.linear_interpolate(new_translation, delta)
		rotation = rotation.linear_interpolate(new_rotation, delta)
	else:
		translation = new_translation
		rotation = new_rotation
		
func _on_StepTimer_timeout():				#this is optimized
	Global.play_rand(step_sound, steps)

func _on_RespawnTimer_timeout():
	respawn()
	
func _on_InvulTimer_timeout():
	is_invul = false

const noclip_help = "Set player noclip"
func noclip_cmd(command):
	if network.cheats and command != null:
		noclip = bool(int(command))
		print("Noclip is set to " + str(noclip))
		Console.print("Noclip is set to " + str(noclip))
	elif command == null:
		print("No argument given!")
		Console.print("No argument given!")
	else:
		print("cheats is not set to true!")
		Console.print("cheats is not set to true!")
		
const interp_help = "Whether to interpolate player movement for multiplayer"
func interp_cmd(command):
	if network.cheats and command != null:
		interp = bool(int(command))
		print("Interpolation is set to " + str(interp))
		Console.print("Interpolation is set to " + str(interp))
	elif command == null:
		print("No argument given!")
		Console.print("No argument given!")
	else:
		print("cheats is not set to true!")
		Console.print("cheats is not set to true!")
		
const interp_scale_help = "How much to scale the interpolation"
func interp_scale_cmd(command):
	if network.cheats and command != null:
		interp_scale = int(command)
		print("Interpolation scale is set to " + str(interp_scale))
		Console.print("Interpolation scale is set to " + str(interp_scale))
	elif command == null:
		print("No argument given!")
		Console.print("No argument given!")
	else:
		print("cheats is not set to true!")
		Console.print("cheats is not set to true!")

const kill_help = "Kills self"
func kill_cmd():
	damage(player_info["health"])
