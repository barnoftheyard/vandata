extends Control

var crosshair = 0

func _process(_delta):
	$Crosshair.frame = crosshair

func _on_Button_pressed():
	if crosshair > 0:
		crosshair -= 1
func _on_Button2_pressed():
	if crosshair < 64:
		crosshair += 1
