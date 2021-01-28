extends Area

var water_density = 997
var target = null

func _on_Water_body_entered(body):
	target = body
	if body is KinematicBody:
		body.is_inwater = true
		body.player_info["speed"] *= 0.75

func _on_Water_body_exited(body):
	target = null
	if body is KinematicBody:
		body.is_inwater = false
		body.player_info["speed"] = body.RUN_SPEED

func _physics_process(delta):
	if is_instance_valid(target) and overlaps_body(target):
		if target is KinematicBody:
			target.vel.y *= (target.GRAVITY / water_density) * delta * -1
		elif target is RigidBody:
			target.add_central_force(Vector3(0, 10, 0) * delta)
