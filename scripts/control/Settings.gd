extends Control

onready var options = $AspectRatioContainer/ScrollContainer/OptionsList

func init_config():		#I should really set up some sort of clever for loop that takes care of all the path-setting for me
	Global.config_file.set_value("game", "player_name", 
	options.get_node("PlayerName/VBoxContainer/LineEdit").text)
	Global.config_file.set_value("game", "crosshair", 
	options.get_node("Crosshair/VBoxContainer/HBoxContainer/CrosshairSub").crosshair)		#game = unique to the user's program instance
	Global.config_file.set_value("game", "invert_x", 
	options.get_node("InvertMouse/VBboxContainer/CheckBox1").is_pressed())
	Global.config_file.set_value("game", "invert_y", 
	options.get_node("InvertMouse/VBboxContainer/CheckBox2").is_pressed())
	Global.config_file.set_value("game", "flip_guns", 
	options.get_node("Visuals/VBoxContainer/CheckBox3").is_pressed())
	Global.config_file.set_value("game", "fullscreen", 
	options.get_node("Visuals/VBoxContainer/CheckBox1").is_pressed())
	Global.config_file.set_value("game", "show_fps",
	options.get_node("Visuals/VBoxContainer/CheckBox2").is_pressed())
	Global.config_file.set_value("game", "mouse_sensitivity", 
	options.get_node("MouseSensitivity/VBoxContainer/MouseSenseSlider").value)
	Global.config_file.set_value("game", "fov", 
	options.get_node("Fov/VBoxContainer/FovSlider").value)
	Global.config_file.set_value("game", "spray", 
	options.get_node("Spray/VBoxContainer/HBoxContainer/TextureRect").texture.resource_path)
	
func set_settings():
	options.get_node("PlayerName/VBoxContainer/LineEdit").text = Global.game_config["player_name"]
	options.get_node("Crosshair/VBoxContainer/HBoxContainer/CrosshairSub").crosshair = Global.game_config["crosshair"]
	options.get_node("InvertMouse/VBboxContainer/CheckBox1").pressed = Global.game_config["invert_x"]
	options.get_node("InvertMouse/VBboxContainer/CheckBox2").pressed = Global.game_config["invert_y"]
	options.get_node("Visuals/VBoxContainer/CheckBox3").pressed = Global.game_config["flip_guns"]
	options.get_node("Visuals/VBoxContainer/CheckBox1").pressed = Global.game_config["fullscreen"]
	options.get_node("Visuals/VBoxContainer/CheckBox2").pressed = Global.game_config["show_fps"]
	options.get_node("MouseSensitivity/VBoxContainer/MouseSenseSlider").value = Global.game_config["mouse_sensitivity"]
	options.get_node("MouseSensitivity/VBoxContainer/HBoxContainer/LineEdit").text = str(Global.game_config["mouse_sensitivity"])
	options.get_node("Fov/VBoxContainer/FovSlider").value = Global.game_config["fov"]
	options.get_node("Fov/VBoxContainer/HBoxContainer/FovEdit").text = str(Global.game_config["fov"])
	options.get_node("Spray/VBoxContainer/HBoxContainer/TextureRect").texture = load(Global.game_config["spray"])
	
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
	options.get_node("MouseSensitivity/VBoxContainer/HBoxContainer/LineEdit").text = str(value)
func _on_LineEdit_text_entered(new_text):
	options.get_node("MouseSensitivity/VBoxContainer/MouseSenseSlider").value = float(new_text)


func _on_FovSlider_value_changed(value):
	options.get_node("Fov/VBoxContainer/HBoxContainer/FovEdit").text = str(value)
func _on_FovEdit_text_entered(new_text):
	options.get_node("Fov/VBoxContainer/FovSlider").value = float(new_text)


func _on_Back_pressed():
	queue_free()


func _on_Load_pressed():
	$SprayFileDialog.popup_centered()


func _on_SprayFileDialog_file_selected(path):
	options.get_node("Spray/VBoxContainer/HBoxContainer/TextureRect").texture = load(path)
