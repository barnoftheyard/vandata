extends KinematicBody
class_name Uav

const GRAVITY = -24.8
const ACCEL = 4
const DEACCEL = 8

const UAV = true

var vel = Vector3()
var accel = 0
var targets = []
var last_body = null

var is_dead = false

export var health = 25
export var speed = 8
export var interp = true

var p = 0.2
var i = 0.05
var d = 1.0

func bullet_hit(damage, id, _bullet_hit_pos, _force_multiplier):
	health -= damage
	
	if health <= 0 and !is_dead:
		var killer = get_node("/root/characters/" + id)
		print("UAV killed by " + killer.player_info["name"])
		
		killer.get_node("Hud").chat_box.text += ("UAV killed by " + killer.player_info["name"] + "\n")
		$Timer.start()
		$hover.stop()
		is_dead = true

func _ready():
	$hover.play()
	$uav/X.rotate_y(deg2rad(90))

func _physics_process(delta):
	var dir = Vector3()
	
	$RayCast.force_raycast_update()
	if $RayCast.is_colliding() and !$RayCast.get_collider() is Player and !is_dead:
		var distance =  $RayCast.get_collision_point().y - $RayCast.translation.y
		if distance < 4:
			vel.y += distance * speed * 2 * delta
		elif distance > 4:
			vel.y -= distance * speed * 2 * delta
		else:
			vel.y = 0
	else:
		vel.y += GRAVITY * delta
	
	var hvel = vel
	
	if targets != null:
		for target in targets:		#go through all bodies that we collected and apply our shit
			if (is_instance_valid(target) and $Area.overlaps_body(target)
			and not "UAV" in target and target is Player and !is_dead):
				
				if target.translation.distance_to(self.translation) > 6:
					dir = translation.direction_to(target.translation)

				var new_transform = transform.looking_at(target.global_transform.origin, Vector3.UP)
				transform = transform.interpolate_with(new_transform, ACCEL * delta)
				rotation.x = 0
				rotation.z = 0
				
				var new_transform_x = $uav/X.transform.looking_at(target.global_transform.origin, Vector3.UP)
				$uav/X.transform = $uav/X.transform.interpolate_with(new_transform_x, ACCEL * delta)
				$uav/X.rotation.x = 0
				$uav/X.rotation.y = 0

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
	if body is KinematicBody and last_body != body:
		targets.append(body)
		last_body = body
