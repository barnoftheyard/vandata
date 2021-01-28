extends Button

var hovering = false
var just_pressed = false

func check_button():
	if self.is_hovered() and !hovering:
		$Hover.play()
		hovering = true
	elif !self.is_hovered() and hovering:
		hovering = false
		
	if self.pressed and !just_pressed:
		$Select.play()
		just_pressed = true
		return true
		
	elif !self.pressed and just_pressed:
		just_pressed = false
		return false


func _process(_delta):
	check_button()
