extends Spatial

onready var a = $TeleTopRight/ExitPoint.global_transform.origin
onready var b = $TeleTopLeft/ExitPoint.global_transform.origin

func _on_TeleTopLeft_body_entered(body):
	if body is KinematicBody:
		body.translation = a
		body.rotate_y(deg2rad(180))
		$TeleTopRight/TeleExitB.play()
		$TeleTopLeft/TeleEnterB.play()


func _on_TeleTopRight_body_entered(body):
	if body is KinematicBody:
		body.translation = b
		body.rotate_y(deg2rad(180))
		
		$TeleTopLeft/TeleExitA.play()
		$TeleTopRight/TeleEnterA.play()
