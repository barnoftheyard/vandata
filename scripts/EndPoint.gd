extends Spatial

export var velocity = Vector3()
onready var prev_pos = Vector3(0, 0 ,0)

func _physics_process(delta):
	
	velocity = (global_transform.origin - prev_pos)
	
	prev_pos = global_transform.origin
