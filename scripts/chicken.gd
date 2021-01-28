extends KinematicBody
class_name Chicken

const GRAVITY = -24.8
const ACCEL = 8

const CHICKEN = true

var vel = Vector3()
var targets = []
var last_body = null

var health = 15

func bullet_hit(damage, id, _bullet_hit_pos, _force_multiplier):
	health -= damage
	
	if health <= 0:
		$chicken/AnimationPlayer.play("death")
		print("Chicken killed by " + get_node("/root/characters/" + id).player_info["name"])

func _ready():
	$chicken/AnimationPlayer.play("idle -loop")
	$chicken/AnimationPlayer.connect("animation_finished", self, 
	"_on_AnimationPlayer_animation_finished")
	
func _physics_process(delta):
	var dir = Vector3()
	
	vel.y += GRAVITY * delta
	
	var hvel = vel
	hvel.y = 0
	
	var accel = ACCEL
	
	if targets != null:
		for target in targets:		#go through all bodies that we collected and apply our shit
			if (is_instance_valid(target) and $Area.overlaps_body(target)
			and not "CHICKEN" in target):
				var move = self.translation - target.translation
				dir = move
				dir.y = 0
				dir.normalized()
				
					
				self.rotation.x = 0
				self.rotation.z = 0
		
	if dir.dot(hvel) > 0:
		accel = ACCEL
		
	hvel = hvel.linear_interpolate(dir * 1, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	
	vel = move_and_slide(vel, Vector3(0, 1, 0), false, 4, deg2rad(40), false)

func _on_Timer_timeout():
	queue_free()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "death":
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
