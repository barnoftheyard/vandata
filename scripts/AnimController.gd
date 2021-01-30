extends Spatial

#some of the animation code is in its own file because its quite ugly to look at sometimes
#this is just to free up some space in the main script

var anim_strafe_interp = 0
var anim_strafe_dir_interp = 0

var jumpscale = 0
var anim_run_interp = 0			#KEEP THIS, IT DOES THE INERTIA OF THE ANIMATIONS

var tilt = 0

onready var anim_tree = $ussr_male.get_node("AnimationTree")
onready var model_transform = Quat($ussr_male.transform.basis)

enum states {PASSIVE, ARMED}

#func set_bone_x_rotation(skeleton, bone_name, x_rot):
#	var head = skeleton.find_bone(bone_name)
#	var head_transform = skeleton.get_bone_rest(head)
#
#	head_transform = head_transform.rotated(Vector3(1, 0, 0), x_rot)
#	skeleton.set_bone_pose(head, head_transform)

func _ready():
	$ussr_male/Armature/Skeleton/SkeletonIK.start()

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
	else:
		anim_run_interp -= delta * ACCEL		#-1 = idle
			
	anim_tree.set("parameters/Blend3/blend_amount", anim_run_interp)
	
	tilt = clamp(get_parent().get_node("Camera").rotation_degrees.x, -65, 65)
	$ussr_male/Armature/Skeleton/tilt.rotation_degrees.x = -tilt
	$ussr_male/Armature/Skeleton/tilt.rset("rotation_degrees.x", -tilt)
	
sync func network_update(new_anim_strafe_interp, new_anim_strafe_dir_interp,
	new_jumpscale, new_anim_run_interp, new_tilt):
	anim_strafe_interp = new_anim_strafe_interp
	anim_strafe_dir_interp = new_anim_strafe_dir_interp
	jumpscale = new_jumpscale
	anim_run_interp = new_anim_run_interp
	tilt = new_tilt
	
func _on_change_playermodel_weapon(weapon):
	anim_tree.set("parameters/strafe_dir/blend_amount", 1)
	$ussr_male/Armature/Skeleton/hand_r/helper.show()
