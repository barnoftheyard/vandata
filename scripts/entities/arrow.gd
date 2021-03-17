extends Spatial

export var damage = 50
export var from = ""

var arrow_model = preload("res://models/bow/arrow.obj")

func _on_arrow_body_entered(body):
	
	if body.has_method("bullet_hit"):
		if body is Player and body.is_player:
			#serverside, fire damage, id, collision point, and force
			body.rpc_id(int(body.name), "bullet_hit", damage, from, translation, 0.5)
		#if not, its an NPC/physics object
		else:
			#clientside, fire damage, id, collision point, and force
			body.bullet_hit(damage, from, translation, 0.5)
			
	self.sleeping = true
	var model = MeshInstance.new()
	body.add_child(model)
	self.angular_velocity = Vector3.ZERO
	model.mesh = arrow_model
	model.global_transform = global_transform
	
	queue_free()
	
