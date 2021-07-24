extends KinematicBody
class_name Chicken

const GRAVITY = -24.8
const ACCEL = 4
const DEACCEL = 8

const CHICKEN = true

var vel = Vector3()
var accel = 0
var targets = []
var last_body = null

var anim_run_interp = 0

export var health = 15
export var speed = 8
export var interp = true

func bullet_hit(damage, id, _bullet_hit_pos, _force_multiplier):
	health -= damage
	
	if health <= 0:
		$chicken/AnimationPlayer2.play("ChickenDeath")
		if id in network.player_list:
			var killer = get_node("/root/characters/" + id)
			print("Chicken killed by " + killer.player_info["name"])
			
			killer.get_node("Hud").chat_box.text += ("Chicken killed by " + killer.player_info["name"] + "\n")

func _ready():
	$chicken/AnimationPlayer2.connect("animation_finished", self, "_on_AnimationPlayer2_animation_finished")
	$chicken/AnimationPlayer.play("idle -loop")
	
func _physics_process(delta):
	var dir = Vector3()
	
	vel.y += GRAVITY * delta
	
	var hvel = vel
	hvel.y = 0
	
	if targets != null:
		for target in targets:		#go through all bodies that we collected and apply our shit
			if (is_instance_valid(target) and $Area.overlaps_body(target)
			and not "CHICKEN" in target):
				dir = -translation.direction_to(target.translation)
				dir.y = 0

				var new_transform = transform.looking_at(target.global_transform.origin, Vector3.UP)
				transform  = transform.interpolate_with(new_transform, ACCEL * delta)
				
				rotation.x = 0
				rotation.z = 0
				scale = Vector3(0.25, 0.25, 0.25)

	anim_run_interp = clamp(anim_run_interp, 0, 1)
	if dir.dot(hvel) > 0:
		accel = ACCEL
		anim_run_interp += delta * ACCEL		#1 = run
	else:
		accel = DEACCEL
		anim_run_interp -= delta * DEACCEL		#0 = idle
	$chicken/AnimationTree.set("parameters/Blend2/blend_amount", anim_run_interp)
		
	hvel = hvel.linear_interpolate(dir * speed, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	
	vel = move_and_slide(vel, Vector3(0, 1, 0), false, 4, deg2rad(40), false)
	
	if get_tree().get_network_peer() != null:
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

func _on_AnimationPlayer2_animation_finished(anim_name):
	if anim_name == "ChickenDeath":
		$chicken/Armature.hide()
		$ChickenDeath.play()
		$CollisionShape.disabled = true
		$Timer.start()
		$Particles.emitting = true


func _on_Area_body_entered(body):
	#if our body is a KinematicBody, and isn't the same one we just added
	if body is KinematicBody and last_body != body:
		targets.append(body)
		last_body = body
