extends Control

func init_config():		#I should really set up some sort of clever for loop that takes care of all the path-setting for me
	Global.config_file.set_value("game", "player_name", $PlayerNameSub/LineEdit.text)
	Global.config_file.set_value("game", "crosshair", $CrosshairSub.crosshair)		#game = unique to the user's program instance
	Global.config_file.set_value("game", "invert_x", $InvertCameraSub/CheckBox.is_pressed())
	Global.config_file.set_value("game", "invert_y", $InvertCameraSub/CheckBox2.is_pressed())
	Global.config_file.set_value("game", "flip_guns", $CheckBox5.is_pressed())
	Global.config_file.set_value("game", "fullscreen", $CheckBox3.is_pressed())
	Global.config_file.set_value("game", "show_fps", $CheckBox4.is_pressed())
	Global.config_file.set_value("game", "mouse_sensitivity", $MouseSenseSlider.value)
	Global.config_file.set_value("game", "fov", $FovSlider.value)
	
func set_settings():
	$PlayerNameSub/LineEdit.text = Global.game_config["player_name"]
	$CrosshairSub.crosshair = Global.game_config["crosshair"]
	$InvertCameraSub/CheckBox.pressed = Global.game_config["invert_x"]
	$InvertCameraSub/CheckBox2.pressed = Global.game_config["invert_y"]
	$CheckBox5.pressed = Global.game_config["flip_guns"]
	$CheckBox3.pressed = Global.game_config["fullscreen"]
	$CheckBox4.pressed = Global.game_config["show_fps"]
	$MouseSenseSlider.value = Global.game_config["mouse_sensitivity"]
	$MouseSenseSlider/LineEdit.text = str(Global.game_config["mouse_sensitivity"])
	$FovSlider.value = Global.game_config["fov"]
	$FovSlider/FovEdit.text = str(Global.game_config["fov"])
	
func _ready():
	set_settings()
	
func _on_Resolution_pressed():
	$PopupMenu.popup()

func _on_PopupMenu_id_pressed(id):
	if id == 1:
		pass

func _on_Save_pressed():
	init_config()
	Global.config_file.save(Global.file_name)
	Global.load_config()


func _on_MouseSenseSlider_value_changed(value):
	$MouseSenseSlider/LineEdit.text = str(value)
func _on_LineEdit_text_entered(new_text):
	$MouseSenseSlider.value = float(new_text)


func _on_FovSlider_value_changed(value):
	$FovSlider/FovEdit.text = str(value)
func _on_FovEdit_text_entered(new_text):
	$FovSlider.value = float(new_text)


func _on_Back_pressed():
	queue_free()
