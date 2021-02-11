extends Controller
class_name Bot

var targets = []
var last_body = null

func _ready():
	player.is_player = false

func _physics_process(delta):
	var dir = Vector3()
	
	if targets != []:
		for target in targets:		#go through all bodies that we collected and apply our shit
			if is_instance_valid(target):
				dir = -player.translation.direction_to(target.translation)
				dir.y = 0
				
				var new_transform = player.transform.looking_at(target.global_transform.origin, Vector3.UP)
				player.transform  = player.transform.interpolate_with(new_transform, 3 * delta)
				
				player.rotation.x = 0
				player.rotation.z = 0
				
				
func _on_Area_body_entered(body):
	#if our body is a KinematicBody, and isn't the same one we just added
	if body is KinematicBody and last_body != body:
		targets.append(body)
		last_body = body
		print(targets)
		
func is_bot():
	return true
