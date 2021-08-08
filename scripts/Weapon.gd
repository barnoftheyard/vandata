extends Spatial

export var sway = 5

var pos = 0
var player_node = null

#Our current animation player
var anim = null

var muzzle_flash = null

var grab = false
var grab_target = null

export var consume_ammo = true
export var instant_reload = false
export var recoil = true
export var disabled = false

onready var hitscan = $ViewportContainer/Viewport/TransformHelper/Hitscan
onready var hitscan_initpos = hitscan.translation

onready var weapon_nodes = hitscan.get_children()
#get the number of children and offset the index by 1 to account for arrays
onready var weapon_num = hitscan.get_child_count() - 1
onready var bullet_holes = Global.files_in_dir("res://textures/bullethole/", ".png")

var weapon_name = ""

onready var guns_flipped = Global.game_config["flip_guns"]

var decal = preload("res://scenes/decal.tscn")

#the list of weapon definitions
var weapons = {
	"pistol": {
		"clip": 12, 
		"ammo": 144, 
		"recoil": 2,
		"times_fired": 0
	},
	"smg": {
		"clip": 30, 
		"ammo": 30,
		"recoil": 1,
		"times_fired": 0
	},
	"br": {
		"clip": 20, 
		"ammo": 128,
		"recoil": 3,
		"times_fired": 0
	},
	"auto5": {
		"clip": 6, 
		"ammo": 36,
		"recoil": 1,
		"times_fired": 0
	},
	"double barrel": {
		"clip": 2, 
		"ammo": 24,
		"recoil": 1,
		"times_fired": 0
	},
	"grenade": {
		"clip": null,
		"ammo": 6,
		"recoil": null,
		"times_fired": 0
	},
	"bow": {
		"clip": 1,
		"ammo": 12,
		"recoil": null,
		"times_fired": 0
	},
	"shovel": {
		"clip": null,
		"ammo": null,
		"recoil": 1,
		"times_fired": null
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

var can_spray = true
var previous_spray = null

signal finished_reloading
signal update_weapon_list
signal weapon_switch

signal change_playermodel_weapon(weapon)

#the weapon name that we started reloading
var da_wep = null

#Our hitscan weapon firing function
func fire_weapon(damage, bullets, sound):
	anim.play("fire")
	fire_hitscan(damage, 2048)
	sound.play()
	
	if muzzle_flash != null:
		muzzle_flash.show()
		muzzle_flash.get_node("AnimationPlayer").play("fire")
		muzzle_flash.get_node("Timer").start()
	
	if consume_ammo:
		weapons[weapon_name]["clip"] -= bullets
		weapons[weapon_name]["times_fired"] += bullets
		
	if recoil:
		player_node.get_node("Camera").rotation_degrees.x += weapons[weapon_name]["recoil"]
		
func melee_weapon(damage):
	#anim.play("swing")
	fire_hitscan(damage, 4)
	#sound.play()
	
	if recoil:
		player_node.get_node("Camera").rotation_degrees.x += weapons[weapon_name]["recoil"]

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
		weapon_nodes[pos].get_node("Reload").play()
	else:
		_on_animation_finished("reload")
	
#switch to specific weapon index
func switch_weapon(index):
	
	pos += index
	if pos > weapon_num:			#don't go past our total number of weapons available
		pos = weapon_num
	#-1 means no weapons in our inventory. 0 means one, as the weapon index is offset by 1
	#because arrays :P
	elif pos < 0:
		pos = 0
		
	if pos <= -1 or pos - index <= -1:
		return
		
	weapon_nodes[pos - index].hide()
	weapon_nodes[pos].show()
	
	#if the previous weapon has an animationplayer
	if weapon_nodes[pos - index].has_node("AnimationPlayer"):
		var previous = weapon_nodes[pos - index].get_node("AnimationPlayer")
		#is our weapon connected?
		if previous.is_connected("animation_finished", self, "_on_animation_finished"):
			previous.disconnect("animation_finished", self, "_on_animation_finished")
		
	#if the current weapon has an animationplayer
	if weapon_nodes[pos].has_node("AnimationPlayer"):
		#set the anim to the current weapon
		anim = weapon_nodes[pos].get_node("AnimationPlayer")
		if !anim.is_connected("animation_finished", self, "_on_animation_finished"):
			anim.connect("animation_finished", self, "_on_animation_finished")
		
		#set the path of our muzzle flash scene to our variable
		muzzle_flash = weapon_nodes[pos].get_node_or_null("muzzle_flash")
	else:
		#clean up!
		anim = null
		muzzle_flash = null
		
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
	
func remove_all_weapons():
	for n in hitscan.get_children():
		hitscan.remove_child(n)
		n.queue_free()
	#reset pos
	pos = 0
		
	_on_update_weapon_list()
	
func put_away_weapon():
	$Tween.interpolate_property(hitscan, "translation", hitscan_initpos, 
	Vector3(0, -2, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	disabled = true
	
func bring_out_weapon():
	$Tween.interpolate_property(hitscan, "translation", Vector3(0, -2, 0), 
	hitscan_initpos, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	disabled = false
	
func create_decal(body, trans, normal, color, decal_scale, image_path):
	var b = decal.instance()
	body.add_child(b)
	b.global_transform.origin = trans
	#get translation and rotation
	var c = trans + normal
	
	#this just prevents a look_at error that reports if our target vector is equal to UP
	if c != Vector3.UP:
		b.look_at(c, Vector3.UP)
	
	#rotate the decal around on the X axis
	b.rotation.x *= -1
	
	var texture = load(image_path)
	
	var decal_shader = b.get_node("MeshInstance").mesh.material
	decal_shader.set_shader_param("albedo", 
	texture)
	
	#decal_shader.set_shader_param("uv_scale", Vector2.ONE * decal_scale)
	
	decal_shader.set_shader_param("albedo_tint", color)
	b.get_node("MeshInstance").mesh.size = Vector3.ONE * decal_scale
	
	#return the node
	return b
	
func spray():
	var ray = $UseCast
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var body = ray.get_collider()
		
		if body is StaticBody and can_spray:
			#is our previous spray node valid? if so remove it
			if is_instance_valid(previous_spray):
				previous_spray.queue_free()
			
			#create our spray with on the static body
			var spray = create_decal(body, ray.get_collision_point(), ray.get_collision_normal(), 
			Color(1, 1, 1, 1), 1, Global.game_config["spray"])
			#stop the despawn timer
			spray.get_node("Timer").stop()
			#play the spray sound
			$spray.play()
			#set our previous spray variable to our current one
			previous_spray = spray
			
			#set that we can't spray until the timer times out, until then, yield this
			#function
			can_spray = false
			$SprayTimer.start()
			yield($SprayTimer, "timeout")
			can_spray = true
			
func fire_hitscan(damage, ray_range):
	var ray = $RayCast
	ray.cast_to.z = -ray_range
		
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var body = ray.get_collider()
		
		#if we hit ourselves somehow, ignore
		if body == player_node:
			pass
		#check if we can call the function on the node
		elif body.has_method("bullet_hit"):
			body.rpc_config("bullet_hit", MultiplayerAPI.RPC_MODE_REMOTESYNC)
			#is it a player?
			if body is Player and body.is_player:
				#serverside, fire damage, id, collision point, and force
				body.rpc_id(int(body.name), "bullet_hit", damage, player_node.name, ray.get_collision_point(), 0.5)
			#if not, its an NPC/physics object
			else:
				#clientside, fire damage, id, collision point, and force
				body.rpc("bullet_hit", damage, player_node.name, ray.get_collision_point(), 0.5)
				
#		elif body is StaticBody:
#			#bullet decal adding
#			create_decal(body, ray.get_collision_point(), ray.get_collision_normal(), 
#			Color(1, 1, 1, 1), 0.5, 
#			bullet_holes[Global.rng.randi_range(0, bullet_holes.size() - 1)])
			
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
			
			if grab:
				put_away_weapon()
			else:
				bring_out_weapon()
			
		elif body.has_method("use"):
			body.rpc_config("use", MultiplayerAPI.RPC_MODE_REMOTESYNC)
			if body is Ladder:
				body.rpc("use", player_node)
			else:
				body.rpc("use")
			
	else:
		grab = false

func _ready():
	connect("weapon_switch", self, "_on_weapon_switch")
	connect("finished_reloading", self, "_on_finished_reloading")
	
	Console.connect_node(self)
	
	#connect to the player's animation controller
	connect("change_playermodel_weapon", get_node("../../AnimController"),
		"_on_change_playermodel_weapon")
		
	if weapon_num > 0:
		weapon_name = weapon_nodes[pos].get_name()
		weapon_nodes[pos].show()		#so that it shows up when it first loads
		switch_weapon(0)
		
			
func _input(event):
	if !Global.is_paused:
		if event is InputEventMouseButton and event.is_pressed() and weapon_num >= 1:			#perform weapon switching
			
			if event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN:
				if event.button_index == BUTTON_WHEEL_UP and pos < weapon_num:	#ignore is_pressed, godot still registers scroll-wheel movement as a button press
					switch_weapon(1)
				
				elif event.button_index == BUTTON_WHEEL_DOWN and pos > 0:
					switch_weapon(-1)
					
				
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			mouse_accel.x = -event.relative.x * 0.0075
			mouse_accel.y = -event.relative.y * 0.0075
		
		#keyboard weapon switching
		if Input.is_action_just_pressed("ui_1"):
			switch_to_weapon("shovel")
		elif Input.is_action_just_pressed("ui_2"):
			switch_to_weapon("pistol")
		elif Input.is_action_just_pressed("ui_3"):
			switch_to_weapon("smg")
		elif Input.is_action_just_pressed("ui_4"):
			switch_to_weapon("br")
		elif Input.is_action_just_pressed("ui_5"):
			switch_to_weapon("bow")
				
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
			#grab_target.mode = RigidBody.MODE_KINEMATIC
			grab_target.gravity_scale = 0
			grab_target.global_transform.origin = grab_target.global_transform.origin.linear_interpolate(
				$UseCast/EndPoint.global_transform.origin, sway * delta)
			
			
		else:
			grab_target.mode = RigidBody.MODE_RIGID
			grab_target.sleeping = false
			grab_target.gravity_scale = 1
			
			#set the velocity of the object when we let go of it (allows throwing)
			#client side
			#grab_target.linear_velocity = ($UseCast/EndPoint.velocity.normalized() + player_node.vel) * (1 / grab_target.mass)
			#server side
			#grab_target.rset_unreliable("linear_velocity", ($UseCast/EndPoint.velocity.normalized() + player_node.vel) * (1 / grab_target.mass))
			
			grab_target = null
			
	if !disabled:
		#visual hud effects
		
		#directional sway
		hitscan.translation = hitscan.translation.linear_interpolate(mouse_accel + hitscan_initpos, sway * delta)
		
		#rotational sway
		hitscan.rotation.y = lerp_angle(hitscan.rotation.y, mouse_accel.x, sway * delta)
		hitscan.rotation.x = lerp_angle(hitscan.rotation.x, mouse_accel.y, sway * delta)
		
		#breathing-esque effect on the weapon
		hitscan.translation.y += cos(Global.delta_time * 2) * 0.0005
		
		#set the SunRotate's transform the the transform of our weapon node's transform
		hitscan.get_parent().transform = get_parent().global_transform
	
	#if we have a muzzle flash, and the time it has finished, hide it
	if muzzle_flash != null and weapon_num > -1:
		if muzzle_flash.get_node("Timer").time_left == 0.0:
			muzzle_flash.hide()
	
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
	
	if !Global.is_paused and player_node.is_network_master() and !disabled:
		if cmd[Command.PRIMARY] and can_fire:
			
			if (weapon_name == "pistol" and current_clip > 0 and 
			weapon_nodes[pos].get_node("Timer").is_stopped() and !anim.current_animation == "reload"):
				weapon_nodes[pos].get_node("Timer").start()
				if anim.is_playing():
					anim.stop(true)
				fire_weapon(15, 1, weapon_nodes[pos].get_node("Fire"))
				
				
			elif (weapon_name == "smg" and current_clip > 0 and 
			weapon_nodes[pos].get_node("Timer").is_stopped() and !anim.current_animation == "reload"):
				weapon_nodes[pos].get_node("Timer").start()
				if anim.is_playing():
					anim.stop(true)
				
				fire_weapon(15, 1, weapon_nodes[pos].get_node("Fire"))
				
			elif (weapon_name == "br" and current_clip > 0 and 
			weapon_nodes[pos].get_node("Timer").is_stopped() and !anim.current_animation == "reload"):
				weapon_nodes[pos].get_node("Timer").start()
				if anim.is_playing():
					anim.stop(true)
				
				fire_weapon(20, 1, weapon_nodes[pos].get_node("Fire"))
				
			if weapon_name == "shovel" and weapon_nodes[pos].get_node("Timer").is_stopped():
				weapon_nodes[pos].get_node("Timer").start()
				if anim.is_playing():
					anim.stop(true)
				melee_weapon(25)
				
			elif (weapon_name == "auto5" and current_clip > 0):
				
				throw_bullet(1, 100)
				
				can_fire = false
				
			elif (weapon_name == "double barrel" and current_clip > 0 and 
			!anim.is_playing() and !anim.current_animation == "reload"):
				fire_weapon(50, 1, $RayCast/DoubleBarrelFire)
				
				can_fire = false
			
			elif weapon_name == "grenade" and can_fire:
				weapon_nodes[pos].get_node("ThrowPower").start()
				
				can_fire = false
				
			elif weapon_name == "bow" and current_clip > 0 and !anim.is_playing():
				weapon_nodes[pos].extend()
				
				can_fire = false
			
			#if we run out of ammo in the clip, we reload
			elif (current_clip == 0 and current_ammo > 0 and !anim.is_playing() 
			and weapon_name != "bow"):
				reload_weapon()
				
			#play empty fire sound if we have zero bullets left in clip
			elif current_clip == 0 and current_ammo == 0 and !anim.is_playing():
				$RayCast/Empty.play()
				
				can_fire = false
				
				
		if Input.is_action_just_released("mouse_left"):
			can_fire = true
				
			if weapon_name == "grenade" and current_ammo > 0:
				var grenade_scene = load("res://scenes/Entities/Grenade.tscn").instance()
				grenade_scene.thrower = player_node.name
				
				var timer = weapon_nodes[pos].get_node("ThrowPower")
				
				get_tree().get_root().add_child(grenade_scene)		#add the grenade to the main world
				#since opengl's forward is negative z, we get the weapon's global basis in negative. 
				#Also everything has to be in global coords. Don't know why
				grenade_scene.global_transform.origin = self.global_transform.origin + -self.global_transform.basis.z
				#starting from our foward location, we get our ThrowPower multiplier and subtract it from out total wait time
				#the less time there was, the more power we have, we then multiply it just so its a bit stronger for our chad muscleman arms
				grenade_scene.apply_central_impulse(-self.global_transform.basis.z * (timer.wait_time - timer.time_left) * 100)
				throw_grenade(1)
			
			#bow shooting code
			elif weapon_name == "bow" and current_clip > 0:
				weapon_nodes[pos].shoot(anim.current_animation_position, player_node.name)
				
				if consume_ammo:
					weapons[weapon_name]["clip"] -= 1
					weapons[weapon_name]["times_fired"] += 1
				
				
		if cmd[Command.SECONDARY] and can_fire:
				
			if (weapon_name == "double barrel" and current_clip > 0 and 
			!anim.is_playing()):
				fire_weapon(100, 2, $RayCast/DoubleBarrelFireBoth)
				
				can_fire = false
				
			elif (weapon_name == "double barrel" and current_clip == 0 
			and current_ammo > 0 and !anim.is_playing() 
			and weapon_name != "bow"):
				reload_weapon()
				
			elif current_clip == 0 and current_ammo == 0 and !anim.is_playing():
				$RayCast/Empty.play()
				
				can_fire = false
				
		if Input.is_action_just_released("mouse_right"):
			can_fire = true
		
		#We don't use just_pressed because we want as little bytes sent over
		elif cmd[Command.RELOAD]:
			
			if (weapon_name in weapons and current_ammo > 0 and 
			times_fired != 0 and !anim.is_playing()):
				if weapon_name == "bow":
					weapon_nodes[pos].reload()
				reload_weapon()
				
	#work-arounds so that the disabled flag doesn't effect these inputs	
	if !Global.is_paused and player_node.is_network_master() and cmd[Command.USE]:
		use_hitscan()
	if !Global.is_paused and player_node.is_network_master() and cmd[Command.SPRAY]:
		spray()

func _on_weapon_switch():
	#we do our one-time logic here after weapon switch
	
	#then do the weapon draw visual and audio effects
	$weaponswap.play()
	$Tween.interpolate_property(hitscan, "translation", Vector3(0, -2, -1), 
	hitscan_initpos, 1, Tween.TRANS_QUART, Tween.EASE_IN_OUT)
	$Tween.start()
	
	_on_update_weapon_list()
	
func _on_animation_finished(anim_name):
	#reload the weapon when the animation finishes
	if anim_name == "reload" and da_wep == weapon_name:
		weapons[weapon_name]["ammo"] -= weapons[weapon_name]["times_fired"]
		
		#If we have less ammo than the times we fired previously, add the difference
		# than add it to clip
		if weapons[weapon_name]["ammo"] < 0:
			weapons[weapon_name]["clip"] += weapons[weapon_name]["ammo"] + weapons[weapon_name]["times_fired"]
			weapons[weapon_name]["ammo"] = 0
		else:
			weapons[weapon_name]["clip"] += weapons[weapon_name]["times_fired"]
			
		weapons[weapon_name]["times_fired"] = 0
		
func _on_update_weapon_list():
	weapon_num = hitscan.get_child_count() - 1
	weapon_nodes = hitscan.get_children()
	
	if weapon_num > -1:
		#get the name of our weapon
		weapon_name = weapon_nodes[pos].get_name()
	else:
		weapon_name = ""
	
	#goes to animation controller
	emit_signal("change_playermodel_weapon", weapon_name)
	
#our weapon related console commands
const ammo_desc = "Enables/disables the consumption of ammo"
const ammo_help = "Enables/disables the consumption of ammo"
func ammo_cmd(command):
	if network.cheats:
		consume_ammo = bool(int(command))
		print("Ammo consumption is set to " + str(consume_ammo))
		Console.print("Ammo consumption is set to " + str(consume_ammo))
	else:
		print("cheats is not set to true!")
		Console.print("cheats is not set to true!")
	
const recoil_desc = "Enables/disables weapon recoil"
const recoil_help = "Enables/disables weapon recoil"
func recoil_cmd(command):
	if network.cheats:
		recoil = bool(int(command))
		print("Recoil is set to " + str(recoil))
		Console.print("Recoil is set to " + str(recoil))
	else:
		print("cheats is not set to true!")
		Console.print("cheats is not set to true!")
		
const give_weapon_help = "Gives player certain weapon"
func give_weapon_cmd(command):
	if network.cheats:
		var weapon_spawn = load("res://scenes/Entities/WeaponPickup.tscn").instance()
		weapon_spawn.to_load = command
		weapon_spawn.remove_on_pickup = true
		player_node.add_child(weapon_spawn)
		weapon_spawn.global_transform.origin = player_node.global_transform.origin
		
		print("Giving " + command)
		Console.print("Giving " + command)
	else:
		print("cheats is not set to true!")
		Console.print("cheats is not set to true!")
