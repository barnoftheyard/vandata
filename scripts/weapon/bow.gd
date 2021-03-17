extends Spatial

var arrow = preload("res://scenes/entities/arrow.tscn")
var force = 0
var from = ""

onready var arrow_init = $Armature/Skeleton/string/arrow.transform

func extend():
	$AnimationPlayer.play("Action")
	$Armature/Skeleton/string/arrow.show()
	
func shoot(time, from_):
	force = -range_lerp(time, 0, $AnimationPlayer.current_animation_length, 1, 5)
	from = from_
	$AnimationPlayer.play("Action", -1, force, true)
	
func reload():
	$Armature/Skeleton/string/arrow.show()
	#$Armature/Skeleton/string/arrow.transform = $reload_from.transform
	$Tween.interpolate_property($Armature/Skeleton/string/arrow, "transform", $reload_from.transform, 
	arrow_init, 1, Tween.TRANS_QUART, Tween.EASE_IN_OUT)
	$Tween.start()

func _on_AnimationPlayer_animation_finished(anim_name):
	if $AnimationPlayer.current_animation_position == 0.0:
		$Armature/Skeleton/string/arrow.hide()
		var a = arrow.instance()
		a.damage = abs(force) * 20
		a.from = from
		get_tree().get_root().add_child(a)
		a.global_transform = $Armature/Skeleton/string/arrow.global_transform
		a.apply_central_impulse(global_transform.basis.z * a.damage * 5)
