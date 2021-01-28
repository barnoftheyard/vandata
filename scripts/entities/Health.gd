extends Area

var health = 100

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties():
	if "health" in properties:
		health = properties["weapon"]

func _on_Health_body_entered(body):
	if body is Player and "player_info" in body:
		if body.player_info["health"] < 100:
			body.player_info["health"] += health
			
			$heal.play()
			$CollisionShape.disabled = true
			hide()
		
func _physics_process(delta):
	rotate_y(delta)
	
	var pulse = cos(Global.delta_time * 2) * 0.005
	translation.y += pulse

func _on_heal_finished():
	$Respawn.start()

func _on_Respawn_timeout():
	$CollisionShape.disabled = false
	show()
