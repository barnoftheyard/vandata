extends KinematicBody
class_name Uav

const GRAVITY = -24.8
const ACCEL = 4
const DEACCEL = 2

const UAV = true

var vel = Vector3()
var accel = 0
var targets = []
var target = null
var last_body = null

var is_dead = false
var laser_on = false

export var health = 100
export var speed = 8
export var interp = true
export var damage = 5
export var hover_height = 6
export var hover_tolerance = 0.1
var target_height = 0

var decal = preload("res://scenes/decal.tscn")

onready var die = Global.files_in_dir("res://sounds/uav/die/", ".wav")

enum states {IDLE, ALERT, AWARE}
var state = states.IDLE

func bullet_hit(damage_, id, _bullet_hit_pos, _force_multiplier):
	
	if !is_dead:
		if health <= 0:
			#execute our dying code
			var killer = get_node("/root/characters/" + id)
			print("UAV killed by " + killer.player_info["name"])
			
			killer.get_node("Hud").chat_box.text += ("UAV killed by " + killer.player_info["name"] + "\n")
			killer.player_info["kills"] += 1
			#$Timer.start()
			#$hover.stop()
			Global.play_rand($die, die)
			$ping/ping_timer.stop()
			$AnimationPlayer.play("die")
			is_dead = true
			
		else:
			health -= damage_
			
			if !is_on_floor():
				$AnimationPlayer.play("hit")
		
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
	b.get_node("MeshInstance").scale = Vector3.ONE * decal_scale
	
	#return the node
	return b
		
func fire_hitscan(damage_):
	var ray = $RayCast2
	var ig = $Laser
	
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var body = ray.get_collider()
		
		if laser_on:
			ig.clear()
			ig.begin(Mesh.PRIMITIVE_LINE_STRIP)
			
			ig.set_color(Color.red)
			ig.add_vertex($head.transform.origin)
			ig.add_vertex(to_local(ray.get_collision_point()))
			
			ig.end()
		
		#check if we can call the function on the node
		if body.has_method("bullet_hit") and $Firerate.is_stopped() and $WhenFire.is_stopped():
			$Firerate.start()
			$fire.play()
			
			#is it a player?
			if body is Player and body.is_player:
				#serverside, fire damage, id, collision point, and force
				body.rpc_id(int(body.name), "bullet_hit", damage_, self.name, ray.get_collision_point(), 0.5)
			#if not, its an NPC/physics object
			else:
				#clientside, fire damage, id, collision point, and force
				body.bullet_hit(damage_, self.name, ray.get_collision_point(), 0.5)

#func _ready():
#	$uav/X.rotate_y(deg2rad(90))

func _physics_process(delta):
	var dir = Vector3()
	
	$RayCast.force_raycast_update()
	if $RayCast.is_colliding() and !$RayCast.get_collider() is Player and !is_dead and state != states.IDLE:
		var distance =  $RayCast.get_collision_point().y - $RayCast.translation.y
		if distance < target_height:
			vel.y += distance * 2 * speed * delta
		elif distance > target_height + hover_tolerance:
			vel.y -= distance * 2 * speed * delta
		else:
			vel.y = 0
	elif is_dead or state == states.IDLE:
		vel.y += GRAVITY * 4 * delta
	else:
		vel.y = 0
	
	var hvel = vel
	
	if !targets.empty():
		target = targets.front()
		
		if (is_instance_valid(target) and $Area.overlaps_body(target)
		and not "UAV" in target and (target is Player or target is Chicken) and !is_dead):
			
			if state != states.AWARE:
				state = states.AWARE
				$lock_on.play()
				$AnimationPlayer.play("start")
				laser_on = true
				$IdleTimer.stop()
				$WhenFire.start()
				$ping/ping_timer.stop()
				
			target_height = hover_height + target.translation.y - self.translation.y
			
			#go foward if we're more than 8 units away
			if target.translation.distance_to(self.translation) > 8:
				dir = translation.direction_to(target.translation).normalized()
			#go backwards if we're less than
			else:
				dir = -translation.direction_to(target.translation).normalized()
			
			#constantly track whatever we're aiming at	
			fire_hitscan(damage)

			var new_transform = transform.looking_at(target.global_transform.origin, Vector3.UP)
			transform = transform.interpolate_with(new_transform, 0.2)
			rotation.x = 0
			rotation.z = 0
			
			var foo = target.global_transform.origin
			var bar = Vector3(foo.x, foo.y + 0.5, foo.z)
			
			var new_transform_x = $uav/X.transform.looking_at(bar, Vector3.UP)
			$uav/X.transform = $uav/X.transform.interpolate_with(new_transform_x, 0.2)
			$uav/X.rotation.x = 0
			$uav/X.rotation.y = 0
			$uav/X.rotation.z = -$uav/X.rotation.z
			
			#autoaim the gun
			var new_transform_z = $RayCast2.global_transform.looking_at(bar, Vector3.UP)
			$RayCast2.global_transform = $RayCast2.global_transform.interpolate_with(new_transform_z, 1)
			$RayCast2.rotation.y = 0
			$RayCast2.rotation.z = 0
			
			$head.translation = $uav/X.translation + Vector3(0.131, 0.7, 0)
			$head.rotation = $uav/X.rotation
			$head.rotation.x = $uav/X.rotation.z
		else:
			if state != states.ALERT and !is_dead:
				state = states.ALERT
				$lock_off.play()
				laser_on = false
				$IdleTimer.start()
				$ping/ping_timer.start()
				
				
			if !is_dead:
				$head.rotation = $head.rotation.linear_interpolate(Vector3.ZERO, speed * delta)
				rotation_degrees.y += sin(Global.delta_time) * 1.5
				target_height = to_local(Vector3(0, hover_height, 0)).y
				
	if is_on_floor():
		$Particles.emitting = false
	else:
		if !$hover.is_playing() and !is_dead:
			$Particles.emitting = true
		

	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL
		
	hvel = hvel.linear_interpolate(dir * speed, accel * delta)
	vel = hvel
	
	vel = move_and_slide(vel, Vector3(0, 1, 0), false, 4, deg2rad(40), false)
	
	rpc_unreliable("network_update", translation, rotation, delta * network.interp_scale)
	
remotesync func network_update(new_translation, new_rotation, delta):
	if interp:
		translation = translation.linear_interpolate(new_translation, delta)
		rotation = rotation.linear_interpolate(new_rotation, delta)
	else:
		translation = new_translation
		rotation = new_rotation

func _on_Timer_timeout():
	queue_free()

func _on_Area_body_entered(body):
	#if our body is a KinematicBody, and isn't the same one we just added
	if body is Player and last_body != body:
		targets.append(body)
		last_body = body


func _on_IdleTimer_timeout():
	if state != states.IDLE and $RayCast.is_colliding():
		state = states.IDLE
		targets = []
		last_body = null
		$AnimationPlayer.play("fade")


func _on_ping_timer_timeout():
	$ping.play()
