extends RigidBody

var played = false

onready var down = Vector3(0, -1, 0)

func _physics_process(_delta):
	var ray = $RayCast
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var body = ray.get_collider()
		if body != null:
			if !played:
				$AnimationPlayer.play("deploy")
				played = true
			else:
				add_central_force(down)
				
				
func _on_ammo_body_entered(_body):
	$AnimationPlayer.play("deploy", -1, -5, true)
