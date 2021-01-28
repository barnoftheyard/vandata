extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	#$shinji/AnimationPlayer.get_animation("walk").set_loop(true)
	#$shinji/AnimationPlayer.play("walk")
	pass
	
# warning-ignore:unused_argument
func _process(delta):
	#$shinji.translate(Vector3(0, 0, ($HSlider.value) * delta))
	
	$shinji/AnimationTree.set("parameters/idle_walk_blend/blend_amount", $HSlider.value)
