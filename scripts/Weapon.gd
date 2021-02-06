extends Spatial

export var sway = 5

var pos = 0
var player_node = null

#Our current animation player
var anim = null

var grab = false
var grab_target = null

export var consume_ammo = true
export var instant_reload = false
export var recoil = true

onready var hitscan = $ViewportContainer/Viewport/Hitscan
onready var hitscan_initpos = Vector3(0.5, -0.6, -1.25)
onready var vmod_initpos = self.translation

onready var weapon_nodes = hitscan.get_children()
#get the number of children and offset the index by 1 to account for arrays
onready var weapon_num = hitscan.get_child_count() - 1

var weapon_name = ""

onready var guns_flipped = Global.game_config["flip_guns"]

var decal = preload("res://scenes/decal.tscn")

#the list of weapon definitions
var weapons = {
	"pistol": {
		"clip": 12, 
		"ammo": 144, 
		"times_fired": 0
	},
	"smg2": {
		"clip": 30, 
		"ammo": 256, 
		"times_fired": 0
	},
	"br": {
		"clip": 20, 
		"ammo": 128, 
		"times_fired": 0
	},
	"auto5": {
		"clip": 6, 
		"ammo": 36, 
		"times_fired": 0
	},
	"double barrel": {
		"clip": 2, 
		"ammo": 24, 
		"times_fired": 0
	},
	"grenade": {
		"clip": null,
		"ammo": 6,
		"times_fired": 0
	}
}

var current_clip = 0
var current_ammo = 0
var times_fired = 0
var active = false
var tilt = Vector2(0, 0)

var mouse_accel = Vector3()

#the player speed that will be updated from the player node
var player_speed = 0
var player_y_vel = 0

#this is just a flag for semi auto guns to check whether the gun has been fired
var can_fire = true

signal finished_reloading
signal weapon_switch

signal change_playermodel_weapon(weapon)


#the weapon name that we started reloading
var da_wep = null

#Our hitscan weapon firing function
func fire_weapon(damage, bullets, sound):
	anim.play("fire")
	fire_hitscan(damage)
	sound.play()
	
	if consume_ammo:
		weapons[weapon_name]["clip"] -= bullets
		weapons[weapon_name]["times_fired"] += bullets
		
	if recoil:
		player_node.get_node("Camera").rotation_degrees.x += 1

#Our grenade throwing function
func throw_grenade(bullets):
	#anim.play("fire")
	#sound.play()
	if consume_ammo:
		weapons[weapon_name]["ammo"] -= bullets

#Our projectile weapon firing function
func throw_bullet(bullets, force):
	#anim.play("fire")
	#sound.play()
	
	var bullet_scene = load("res://scenes/Bullet.tscn").instance()
				
	get_tree().get_root().add_child(bullet_scene)		#add the grenade to the main world
	bullet_scene.global_transform.origin = self.global_transform.origin + -self.global_transform.basis.z
	bullet_scene.apply_central_impulse(-self.global_transform.basis.z * force)
	
	if consume_ammo:
		weapons[weapon_name]["clip"] -= bullets
		weapons[weapon_name]["times_fired"] += bullets

func reload_weapon():
	da_wep = weapon_name
	
	if !instant_reload and anim != null and anim.has_animation("reload"):
		anim.play("reload")
	else:
		_on_animation_finished("reload")
	
#switch to specific weapon index
func switch_weapon(index):
	
	pos += index
	if pos > weapon_num:			#don't go past our total number of weapons available
		pos = weapon_num
	elif pos < -1:
		pos = -1
	weapon_nodes[pos - index].hide()
	weapon_nodes[pos].show()
	
	#if the previous weapon has an animationplayer
	if weapon_nodes[pos - index].has_node("AnimationPlayer"):
		var previous = weapon_nodes[pos - index].get_node("AnimationPlayer")
		#is our weapon connected?
		if previous.is_connected("animation_finished", self, "_on_animation_finished"):
			previous.disconnect("animation_finished", self, "_on_animation_finished")
			#print(weapon_nodes[pos + index].get_name() + " disconnect")
		
	#if the current weapon has an animationplayer
	if weapon_nodes[pos].has_node("AnimationPlayer"):
		#set the anim to the current weapon
		anim = weapon_nodes[pos].get_node("AnimationPlayer")
		if !anim.is_connected("animation_finished", self, "_on_animation_finished"):
			anim.connect("animation_finished", self, "_on_animation_finished")
		#print(weapon_nodes[pos].get_name() + " connect")
	else:
		anim = null
		
	emit_signal("weapon_switch")
	
#switch to specific weapon name
func switch_to_weapon(weapon):
	#start from 0 and count up the list of weapons we have
	var inc = 0
	for x in weapon_nodes:
		if x.name == weapon:
			break
		else:
			inc += 1
			
	switch_weapon(inc - pos)

#func all_subnodes(node):
#	for nodes in node.get_children():
#		if nodes.get_child_count() > 0:
#			print("[" + nodes.get_name() + "]")
#			all_subnodes(nodes)
#		else:
#			# Do something
#			print("- " + nodes.get_name())
			
func fire_hitscan(damage):
	var ray = $RayCast
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var body = ray.get_collider()
		
		#if we hit ourselves somehow, ignore
		if body == player_node:
			pass
		#check if we can call the function on the node
		elif body.has_method("bullet_hit"):
			
			#is it a player?
			if body is Player:
				#serverside, fire damage, id, collision point, and force
				body.rpc_id(int(body.name), "bullet_hit", damage, player_node.name, ray.get_collision_point(), 0.5)
			#if not, its an NPC/physics object
			else:
				#clientside, fire damage, id, collision point, and force
				body.bullet_hit(damage, player_node.name, ray.get_collision_point(), 0.5)
				
				#serverside, fire damage, id, collision point, and force
				#body.rpc("bullet_hit", damage, player_node, ray.get_collision_point(), 0.5)
				
		elif body is StaticBody:
			#bullet decal adding
			var b = decal.instance()
			body.add_child(b)
			b.global_transform.origin = ray.get_collision_point()
			#get translation and rotation
			var c = ray.get_collision_point() + ray.get_collision_normal()
			
			if c != Vector3.UP:
				b.look_at(c, Vector3.UP)
			
func use_hitscan():
	var ray = $UseCast
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var body = ray.get_collider()
		if body == player_node:
			pass
			
		elif body is RigidBody or body is PhysBrush:
			grab = !grab
			grab_target = body
			
		elif body.has_method("use"):
			body.use()
	else:
		grab = false

func _ready():
	connect("weapon_switch", self, "_on_weapon_switch")
	connect("finished_reloading", self, "_on_finished_reloading")
	
	Console.connect_node(self)
	
	connect("change_playermodel_weapon", get_node("../../AnimController"),
		"_on_change_playermodel_weapon")
		
	if weapon_num > 0:
		weapon_name = weapon_nodes[pos].get_name()
		weapon_nodes[pos].show()		#so that it shows up when it first loads
		switch_weapon(0)
		
	#hitscan.get_node("hands/AnimationPlayer").play("idle -loop")
	
			
func _input(event):
	if !Global.is_paused:
		if event is InputEventMouseButton and event.is_pressed() and weapon_num >= 1:			#perform weapon switching
			
			if event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN:
				if event.button_index == BUTTON_WHEEL_UP and pos < weapon_num:	#ignore is_pressed, godot still registers scroll-wheel movement as a button press
					switch_weapon(1)
				
				elif event.button_index == BUTTON_WHEEL_DOWN and pos > -1:
					switch_weapon(-1)
					
				
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			mouse_accel.x = -event.relative.x * 0.0075
			mouse_accel.y = -event.relative.y * 0.0075
				
func _physics_process(delta):
	
	var cmd = player_node.cmd
	var Command = player_node.Command
	
	#has the game config changed since _ready()?
	if guns_flipped != Global.game_config["flip_guns"]:
		#flip sides
		hitscan_initpos.x *= -1
		hitscan.translation.x *= -1
		hitscan.scale.x *= -1
		
		#set the value to the config
		guns_flipped = Global.game_config["flip_guns"]
	
	#object grabbing logic
	if grab_target != null:
		if grab:
			#client side
			grab_target.global_transform.origin = grab_target.global_transform.origin.linear_interpolate(
				$UseCast/EndPoint.global_transform.origin, sway * delta)
			#server side
			grab_target.rset_unreliable("global_transform.origin", grab_target.global_transform.origin.linear_interpolate(
				$UseCast/EndPoint.global_transform.origin, sway * delta))
			
			#put away view model when grabbing
			if can_fire:
				$AnimationPlayer.play_backwards("draw")
			can_fire = false
		else:
			grab_target.sleeping = false
			
			#set the velocity of the object when we let go of it (allows throwing)
			#client side
			grab_target.linear_velocity = ($UseCast/EndPoint.velocity.normalized() + player_node.vel) * (1 / grab_target.mass)
			#server side
			grab_target.rset_unreliable("linear_velocity", ($UseCast/EndPoint.velocity.normalized() + player_node.vel) * (1 / grab_target.mass))
			
			grab_target = null
			#bring out view model when not grabbing
			if !can_fire:
				$AnimationPlayer.play("draw")
			can_fire = true
			
	#directional sway
	if can_fire:
		hitscan.translation = hitscan.translation.linear_interpolate(mouse_accel + hitscan_initpos, sway * delta)
	
	#rotational sway
	hitscan.rotation.y = lerp_angle(hitscan.rotation.y, mouse_accel.x, sway * delta)
	hitscan.rotation.x = lerp_angle(hitscan.rotation.x, mouse_accel.y, sway * delta)
	
	#Recoil
	$RayCast.rotation.y = lerp_angle($RayCast.rotation.y, mouse_accel.x, sway * delta)
	$RayCast.rotation.x = lerp_angle($RayCast.rotation.x, mouse_accel.y, sway * delta)
	
	#breathing-esque effect on the weapon
	hitscan.translation.y += cos(Global.delta_time * 2) * 0.0005
	
	#Used by the player's hud
	#these are read-only
	if weapon_num > -1 and weapons.has(weapon_name):
		current_clip = weapons[weapon_name]["clip"]
		current_ammo = weapons[weapon_name]["ammo"]
		times_fired = weapons[weapon_name]["times_fired"]
	else:
		current_clip = null
		current_ammo = null
		times_fired = null
	
	if !Global.is_paused and player_node.is_network_master():
		if cmd[Command.PRIMARY] and can_fire:
			
			if (weapon_name == "pistol" and current_clip > 0 and 
			!anim.is_playing() and !anim.current_animation == "reload"):
				fire_weapon(15, 1, $RayCast/PistolFire)
				
				can_fire = false
				
			elif (weapon_name == "smg2" and current_clip > 0 and 
			weapon_nodes[pos].get_node("Timer").is_stopped() and !anim.current_animation == "reload"):
				weapon_nodes[pos].get_node("Timer").start()
				if anim.is_playing():
					anim.stop(true)
				
				fire_weapon(15, 1, $RayCast/SmgFire)
				
			elif (weapon_name == "br" and current_clip > 0 and 
			weapon_nodes[pos].get_node("Timer").is_stopped() and !anim.current_animation == "reload"):
				weapon_nodes[pos].get_node("Timer").start()
				if anim.is_playing():
					anim.stop(true)
				
				fire_weapon(20, 1, $RayCast/BrFire)
				
			elif (weapon_name == "auto5" and current_clip > 0):
				
				throw_bullet(1, 100)
				
				can_fire = false
				
			elif (weapon_name == "double barrel" and current_clip > 0 and 
			!anim.is_playing()  and !anim.current_animation == "reload"):
				fire_weapon(50, 1, $RayCast/DoubleBarrelFire)
				
				can_fire = false
			
			elif weapon_name == "grenade":
				weapon_nodes[pos].get_node("ThrowPower").start()
				
				can_fire = false
			
			#play empty fire sound if we have zero bullets left in clip
			elif current_clip == 0:
				$RayCast/Empty.play()
				
				can_fire = false
				
				
		if Input.is_action_just_released("mouse_left"):
			can_fire = true
				
			if weapon_name == "grenade" and current_ammo > 0:
				var grenade_scene = load("res://scenes/Grenade.tscn").instance()
				var timer = weapon_nodes[pos].get_node("ThrowPower")
				
				get_tree().get_root().add_child(grenade_scene)		#add the grenade to the main world
				#since opengl's forward is negative z, we get the weapon's global basis in negative. 
				#Also everything has to be in global coords. Don't know why
				grenade_scene.global_transform.origin = self.global_transform.origin + -self.global_transform.basis.z
				#starting from our foward location, we get our ThrowPower multiplier and subtract it from out total wait time
				#the less time there was, the more power we have, we then multiply it just so its a bit stronger for our chad muscleman arms
				grenade_scene.apply_central_impulse(-self.global_transform.basis.z * (timer.wait_time - timer.time_left) * 200)
				throw_grenade(1)
				
		if cmd[Command.SECONDARY] and can_fire:
				
			if (weapon_name == "double barrel" and current_clip > 0 and 
			!anim.is_playing()):
				fire_weapon(100, 2, $RayCast/DoubleBarrelFireBoth)
				
				can_fire = false
				
			elif current_clip == 0:
				$RayCast/Empty.play()
				
				can_fire = false
				
		if Input.is_action_just_released("mouse_right"):
			can_fire = true
		
		#We don't use just_pressed because we want as little bytes sent over
		elif cmd[Command.RELOAD]:
			
			if (weapon_name == "pistol" and current_ammo > 0 and 
			times_fired != 0 and !anim.is_playing()):
				reload_weapon()
				$RayCast/PistolReload.play()
				
			elif (weapon_name == "smg2" and current_ammo > 0 and 
			times_fired != 0 and !anim.is_playing()):
				reload_weapon()
				$RayCast/SmgReload.play()
				
			elif (weapon_name == "auto5" and current_ammo > 0 and 
			times_fired != 0):
				reload_weapon()
				$RayCast/SmgReload.play()
				
			elif (weapon_name == "br" and current_ammo > 0 and 
			times_fired != 0 and !anim.is_playing()):
				reload_weapon()
				$RayCast/BrReload.play()
				
			elif (weapon_name == "double barrel" and current_ammo > 0 and 
			times_fired != 0 and !anim.is_playing()):
				reload_weapon()
				$RayCast/DoubleBarrelReload.play()
				
		elif Input.is_action_just_pressed("ui_use"):
			use_hitscan()

func _on_weapon_switch():
	
	#we do our one-time logic here after weapon switch
	
	#get the name of our weapon
	weapon_name = weapon_nodes[pos].get_name()
	
	#then do the weapon draw visual and audio effects
	$weaponswap.play()
	$AnimationPlayer.play("draw")
	
	_on_update_weapon_list()
	
func _on_animation_finished(anim_name):
	if anim_name == "reload" and da_wep == weapon_name:
		weapons[weapon_name]["ammo"] -= weapons[weapon_name]["times_fired"]
		weapons[weapon_name]["clip"] += weapons[weapon_name]["times_fired"]
		weapons[weapon_name]["times_fired"] = 0
		
func _on_update_weapon_list():
	weapon_num = hitscan.get_child_count() - 1
	weapon_nodes = hitscan.get_children()
	
	emit_signal("change_playermodel_weapon", weapon_name)
	
const ammo_desc = "Enables/disables the consumption of ammo"
const ammo_help = "Enables/disables the consumption of ammo"
func ammo_cmd():
	consume_ammo = !consume_ammo
	
const recoil_desc = "Enables/disables weapon recoil"
const recoil_help = "Enables/disables weapon recoil"
func recoil_cmd():
	recoil = !recoil
