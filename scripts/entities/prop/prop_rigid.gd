extends RigidBody

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties():
	if "model" in properties:
		var model = MeshInstance.new()
		
		if properties["model"].right(properties["model"].length() - 4) == ".obj":
			model.set_mesh(load("res://" + properties["model"]))
			model.create_convex_collision()
			
			if "material" in properties:
				if properties["material"].right(properties["material"].length() - 4) == ".mtl":
					model.material_override = load("res://" + properties["material"])
				else:
					print("invalid material extension")
					return
		else:
			print("invalid model extension")
			return

func bullet_hit(damage, bullet_hit_pos, force_multiplier):			#handles how bullets push the prop
	var direction_vect = global_transform.origin - bullet_hit_pos
	direction_vect = direction_vect.normalized()
	apply_impulse(bullet_hit_pos, direction_vect * damage * force_multiplier)
