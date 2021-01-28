extends DirectionalLight

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()
		
		
func update_properties():
	var light_node = DirectionalLight.new()

	if 'mangle' in properties:

		var yaw = properties['mangle'].x
		var pitch = properties['mangle'].y
		light_node.rotate(Vector3.UP, deg2rad(180 + yaw))
		light_node.rotate(light_node.global_transform.basis.x, deg2rad(180 + pitch))
		
	var light_brightness = 300
	if 'light' in properties:
		light_brightness = properties['light']
		light_node.set_param(Light.PARAM_ENERGY, light_brightness / 100.0)
		light_node.set_param(Light.PARAM_INDIRECT_ENERGY, light_brightness / 100.0)
		
	var light_range := 1.0
	if 'wait' in properties:
		light_range = properties['wait']
		
		
	light_node.set_shadow(true)
	light_node.set_bake_mode(Light.BAKE_ALL)

	var light_color = Color.white
	if '_color' in properties:
		light_color = properties['_color']

	light_node.set_color(light_color)

	add_child(light_node)

	if is_inside_tree():
		var tree = get_tree()
		if tree:
			var edited_scene_root = tree.get_edited_scene_root()
			if edited_scene_root:
				light_node.set_owner(edited_scene_root)
