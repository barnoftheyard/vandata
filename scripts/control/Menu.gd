extends Control

var maps = {
	"TestArea": "res://scenes/TestArea.tscn",
	"Qodot": "res://scenes/Qodot.tscn",
}

var client = null
var server = null

var selected_map = null
var selected_map_name = null

onready var map_text = $MarginContainer2/ScrollContainer2/VBoxContainer/PanelContainer/HBoxContainer/Map


func _ready():
	
	$Copyright.text = Global.version + " - " + Global.author
	$ViewportContainer/Viewport/AnimationPlayer.playback_speed = 0.1
	$ViewportContainer/Viewport/AnimationPlayer.play("gesture")
	
	#move the console node to the bottom
	get_parent().call_deferred("move_child", get_node("/root/Console"), 
	get_parent().get_child_count() - 1)

	#hide the console if it isn't already hidden
	get_node("/root/Console").hide()
	
func _process(delta):
	$FlavorText.rect_rotation += 200 * delta

func _on_TestAreaButton_pressed():
	selected_map = maps["TestArea"]
	selected_map_name = "TestArea"
	
	map_text.text = "Map: " + selected_map_name
	
	if Global.game_mode == Global.game_modes.SINGLEPLAYER:
		get_tree().change_scene(selected_map)

func _on_Button_pressed():
	selected_map = maps["Qodot"]
	selected_map_name = "Jungle"
	
	map_text.text = "Map: " + selected_map_name
	
	if Global.game_mode == Global.game_modes.SINGLEPLAYER:
		get_tree().change_scene(selected_map)
		
func _on_TestButton_pressed():
	selected_map = maps["ladder test"]
	selected_map_name = "ladder test"
	
	map_text.text = "Map: " + selected_map_name
	
	if Global.game_mode == Global.game_modes.SINGLEPLAYER:
		get_tree().change_scene(selected_map)


func _on_Singleplayer_toggled(button_pressed):
	if button_pressed:
		Global.game_mode = Global.game_modes.SINGLEPLAYER
		
		$MarginContainer/ScrollContainer/VBoxContainer/Multiplayer.pressed = false
		$MarginContainer2.show()
	else:
		Global.game_mode = null
		
		$MarginContainer2.hide()


func _on_Multiplayer_toggled(button_pressed):
	if button_pressed:
		Global.game_mode = Global.game_modes.MULTIPLAYER
		
		$MarginContainer/ScrollContainer/VBoxContainer/Singleplayer.pressed = false
		$MarginContainer2.show()
		$MarginContainer/ScrollContainer/VBoxContainer/Host.show()
		$MarginContainer/ScrollContainer/VBoxContainer/Join.show()
	else:
		Global.game_mode = null
		
		$MarginContainer2.hide()
		$MarginContainer/ScrollContainer/VBoxContainer/Host.hide()
		$MarginContainer/ScrollContainer/VBoxContainer/Join.hide()


func _on_Host_pressed():
	#if there is a selected map and there isn't a server yet
	if selected_map != null:
		#network.server_info.name = $ScrollContainer2/VBoxContainer/PanelContainer/HBoxContainer/ServerEdit.text
		#network.server_info.max_players = 32
		var port = int($MarginContainer2/ScrollContainer2/VBoxContainer/PanelContainer/HBoxContainer/PortEdit.text)
		var server_name = $MarginContainer2/ScrollContainer2/VBoxContainer/PanelContainer/HBoxContainer/ServerEdit.text
	
		# And create the server, using the function previously added into the code
		get_tree().set_network_peer(null)
		network.create_server(selected_map, server_name, port)
		
func _on_ready_to_play():
	#selected_map = maps["Qodot"]	#temp
	get_tree().change_scene(selected_map)

func _on_Join_toggled(button_pressed):

	if button_pressed:
		$MarginContainer2.hide()
		$MarginContainer/ScrollContainer/VBoxContainer/IP.show()
		$MarginContainer/ScrollContainer/VBoxContainer/Port.show()
		$MarginContainer/ScrollContainer/VBoxContainer/JoinServer.show()
	else:
		$MarginContainer2.show()
		$MarginContainer/ScrollContainer/VBoxContainer/IP.hide()
		$MarginContainer/ScrollContainer/VBoxContainer/Port.hide()
		$MarginContainer/ScrollContainer/VBoxContainer/JoinServer.hide()


func _on_JoinServer_pressed():
	selected_map = null
	var port = int($MarginContainer/ScrollContainer/VBoxContainer/Port/HBoxContainer/LineEdit.text)
	var ip = $MarginContainer/ScrollContainer/VBoxContainer/IP/HBoxContainer/LineEdit.text
	
	get_tree().set_network_peer(null)
	network.join_server(ip, port)

func _on_Quit_toggled(button_pressed):
	$QuitDialog.popup_centered()

func _on_AcceptDialog_confirmed():
	get_tree().quit()

func _on_Settings_pressed():
	var settings_node = load("res://scenes/Settings.tscn").instance()
	add_child(settings_node)


func _on_Credits_pressed():
	$CreditsPopup.popup_centered()
