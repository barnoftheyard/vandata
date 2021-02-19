extends Area

export var health = 100
export var remove_on_pickup = false

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
			var difference = (body.player_info["health"] - health) * -1
			body.player_info["health"] += health
			
			print("Health added: ", str(difference))
			body.get_node("Hud").chat_box.text += "Health added: " + str(difference) + "\n"
			
			$heal.play()
			$CollisionShape.disabled = true
			$Respawn.start()
			hide()
		
func _physics_process(delta):
	rotate_y(delta)
	
	var pulse = cos(Global.delta_time * 2) * 0.005
	translation.y += pulse

func _on_Respawn_timeout():
	if remove_on_pickup:
		queue_free()
	else:
		$CollisionShape.disabled = false
		show()
