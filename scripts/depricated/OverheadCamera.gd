extends Camera

var mouse_target

func align_y(pos, xform, new_y):
	var penis = Vector3(new_y.x, new_y.y, new_y.z + 90)
	xform.basis.y = penis
	xform.basis.x = -xform.basis.z.cross(penis)
	xform.basis = xform.basis.orthonormalized()
	xform.origin = pos
	return xform
	
func raycast_from_mouse(mouse_pos):				#get a raycast from mouse
	var ray_start = project_ray_origin(mouse_pos)
	#check for collion 1000 units forward
	var ray_end = ray_start + project_ray_normal(mouse_pos) * 1000
	
	return get_world().direct_space_state.intersect_ray(ray_start, ray_end)

func crosshair(_delta):
	mouse_target = raycast_from_mouse(get_viewport().get_mouse_position())
	
	if mouse_target != null:
		
		var crosshair_pos = Vector3(mouse_target.position.x, mouse_target.position.y + 0.1, mouse_target.position.z)
		$Crosshair.global_transform = align_y(crosshair_pos, $Crosshair.global_transform, mouse_target.normal)
		var crosshair_beat = sin(Global.delta_time * 5) * 0.005				#Make the crosshair pulsate
		$Crosshair.scale.x = $Crosshair.scale.x + crosshair_beat
		$Crosshair.scale.y = $Crosshair.scale.y + crosshair_beat
		#$Crosshair.rotate_y(delta_time)
	
func _on_Player_overhead():
	pass
