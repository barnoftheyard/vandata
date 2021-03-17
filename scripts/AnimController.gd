extends Spatial

#some of the animation code is in its own file because its quite ugly to look at sometimes
#this is just to free up some space in the main script

var anim_strafe_interp = 0
var anim_strafe_dir_interp = 0

var jumpscale = 0
var anim_run_interp = 0			#KEEP THIS, IT DOES THE INERTIA OF THE ANIMATIONS

var tilt = 0
var hurt = 0

onready var player_model = $ussr_male
onready var anim_tree = player_model.get_node("AnimationTree")
onready var model_transform = Quat(player_model.transform.basis)
onready var hitscan = get_parent().get_node("Camera/Weapon").hitscan

enum states {PASSIVE, ARMED}

#func set_bone_x_rotation(skeleton, bone_name, x_rot):
#	var head = skeleton.find_bone(bone_name)
#	var head_transform = skeleton.get_bone_rest(head)
#
#	head_transform = head_transform.rotated(Vector3(1, 0, 0), x_rot)
#	skeleton.set_bone_pose(head, head_transform)

func set_all_meshes_layer_mask(node, value):
	for n in node.get_children():
		if n.get_child_count() > 0:
			set_all_meshes_layer_mask(n, value)
		if n is MeshInstance:
			n.set_layer_mask(value)
	
func _ready():
	anim_tree.set("parameters/aim/blend_amount", 0)
	
	#if we are master and not a bot
	if is_network_master() and get_parent().get_node("controller").has_method("is_player"):
		player_model.get_node("Armature/Skeleton/USSR_Male").set_layer_mask(8)
	else:
		player_model.get_node("Armature/Skeleton/USSR_Male").set_layer_mask(9)

func _physics_process(delta):
	
	var cmd = get_parent().cmd
	var Command = get_parent().Command
	
	var dir = get_parent().dir
	var hvel = get_parent().hvel
	
	var ACCEL = get_parent().ACCEL
	
	if !Global.is_paused:
		
		anim_strafe_interp = clamp(anim_strafe_interp, 0, 1)
		anim_strafe_dir_interp = clamp(anim_strafe_dir_interp, 0, 1)
		
		if cmd[Command.LEFT]:			#nice smoothing of turning while doing strafing
			anim_strafe_interp += delta * ACCEL
			anim_strafe_dir_interp += delta * ACCEL
			
			anim_tree.set("parameters/strafe/add_amount", anim_strafe_interp)
			anim_tree.set("parameters/strafe_dir/blend_amount", anim_strafe_dir_interp)
		elif cmd[Command.RIGHT]:
			
			anim_strafe_interp += delta * ACCEL
			anim_strafe_dir_interp -= delta * ACCEL
				
			anim_tree.set("parameters/strafe/add_amount", anim_strafe_interp)
			anim_tree.set("parameters/strafe_dir/blend_amount", anim_strafe_dir_interp)
		else:
			
			anim_strafe_interp -= delta * ACCEL				#reset to normal
			anim_strafe_dir_interp -= delta * ACCEL
			
			anim_tree.set("parameters/strafe/add_amount", anim_strafe_interp)
			anim_tree.set("parameters/strafe_dir/blend_amount", anim_strafe_dir_interp)
			
		if get_parent().is_on_floor():
			jumpscale = 0
			anim_tree.set("parameters/speed/scale", 1)
		
		else:
			anim_tree.set("parameters/speed/scale", lerp(1, 0.1, jumpscale))
			jumpscale += delta * 2
			if jumpscale > 1:
				jumpscale = 1
				
	anim_run_interp = clamp(anim_run_interp, -1, 1)
	if dir.dot(hvel) > 0:		#dot product: get speed, check if speed is above zero
		anim_run_interp += delta * ACCEL		#1 = run
		hitscan.translation.z += cos(Global.delta_time * get_parent().speed) * 0.015 * anim_run_interp * lerp(1, 0.1, jumpscale)
	else:
		anim_run_interp -= delta * ACCEL		#-1 = idle
			
	anim_tree.set("parameters/Blend3/blend_amount", anim_run_interp)
	
	tilt = -clamp(get_parent().get_node("Camera").rotation_degrees.x, -65, 65)
	$ussr_male/Armature/Skeleton/tilt.rotation_degrees.x = tilt
	
	if hurt > 0:
		anim_tree.set("parameters/hurt/blend_amount", hurt)
		hurt -= 10 * delta
	else:
		anim_tree.set("parameters/hurt/blend_amount", 0)
	
remotesync func network_update(new_anim_strafe_interp, new_anim_strafe_dir_interp,
	new_jumpscale, new_anim_run_interp, new_tilt, new_hurt):
	anim_strafe_interp = new_anim_strafe_interp
	anim_strafe_dir_interp = new_anim_strafe_dir_interp
	jumpscale = new_jumpscale
	anim_run_interp = new_anim_run_interp
	tilt = new_tilt
	hurt = new_hurt
	
func _on_change_playermodel_weapon(weapon):
	anim_tree.set("parameters/aim/blend_amount", 1)
	var helper = $ussr_male/Armature/Skeleton/hand_r/helper
	
	for i in helper.get_children():
		i.hide()
		
	set_all_meshes_layer_mask(helper, 8)
	
	match weapon:
		"pistol":
			helper.get_node("pistol").show()
		"smg2":
			helper.get_node("smg2").show()
		"br":
			helper.get_node("br").show()
		_:
			anim_tree.set("parameters/aim/blend_amount", 0)
