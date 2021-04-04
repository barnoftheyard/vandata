extends Spatial

var left_trans = null
var right_trans = null
var hitscan = null

func get_helpers(node):
	left_trans = null
	right_trans = null
	
	for n in node.get_children():
		if n.get_child_count() > 0:
			get_helpers(n)
		if n is Position3D:
			if n.name == "left":
				left_trans = n
			elif n.name == "right":
				right_trans = n
				
	if left_trans == null and right_trans == null:
		$Armature/Skeleton/USSR_Male.hide()
		$Armature/Skeleton/SkeletonIK.stop()
		$Armature/Skeleton/SkeletonIK2.stop()
	else:
		$Armature/Skeleton/USSR_Male.show()
		$Armature/Skeleton/SkeletonIK.start()
		$Armature/Skeleton/SkeletonIK2.start()

func _ready():
	hitscan = get_node_or_null("../hitscan")
	if hitscan != null:
		get_helpers(hitscan)

func _physics_process(delta):
	if left_trans != null:
		$Armature/Skeleton/left_hand.global_transform = left_trans.global_transform
	if right_trans != null:
		$Armature/Skeleton/right_hand.global_transform = right_trans.global_transform
