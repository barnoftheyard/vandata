extends MeshInstance
class_name PropStatic

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties():
	if "model" in properties:
		
		#does the model path have .obj at the end?
		if properties["model"].right(properties["model"].length() - 4) == ".obj":
			set_mesh(load(properties["model"]))
			
			if "material" in properties:
				if properties["material"].right(properties["material"].length() - 4) == ".mtl":
					self.material_override = load(properties["material"])
				else:
					print("invalid material extension")
					return
		else:
			print("invalid model extension")
			return

	#I don't think trenchbroom does booleans so we'll just check if the value is
	#greater-or-equal to 1
	if "collisions" in properties:
		if properties["collisions"] >= 1 and mesh != null:
			create_convex_collision()
			
	if "scale" in properties:
		self.scale * properties["scale"]
