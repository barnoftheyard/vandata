extends RigidBody

var time = 2

var targets = []
var last_body = null

func _ready():
	$Timer.wait_time = time
	
func _on_Area_body_entered(body):			#get all bodies (that are kine or rigid) that are in area
	#make sure that the object we get isn't one that we got before last time
	if body is KinematicBody or body is RigidBody and last_body != body:
		targets.append(body)
		last_body = body

func _on_Timer_timeout():
	if targets != null:
		for target in targets:		#go through all bodies that we collected and apply our shit
			if (is_instance_valid(target) and $Area.overlaps_body(target) and 
			target.has_method("bullet_hit") and $Timer.is_stopped()):
				var distance = Global.distance(target.translation, self.translation)
				var explosion_force_dir = self.translation - target.translation		#get the direction force by subtracting
				explosion_force_dir.normalized()
				
				if distance >= 1:
					target.bullet_hit(100 * (1 / distance), explosion_force_dir, 10)
				else:			#to prevent divide by zero or divide by some hilariously low-
					target.bullet_hit(100, explosion_force_dir, 10)	#decimal when players get too close
				
	#do our clean up after explosion
	$MeshInstance.hide()
	#$Area/DebugMesh.show()
	$Area/Particles.emitting = true
	$Area/OmniLight.show()
	$TimerToDeletion.start()
	$Explosion.play()
	self.mode = MODE_STATIC

func _on_TimerToDeletion_timeout():
	queue_free()
