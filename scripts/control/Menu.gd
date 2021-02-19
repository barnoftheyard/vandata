extends Control

var maps = {
	"TestArea": "res://scenes/TestArea.tscn",
	"Qodot": "res://scenes/Qodot.tscn"
}

var client = null
var server = null

var selected_map = null
var selected_map_name = null

onready var map_text = $ScrollContainer2/VBoxContainer/PanelContainer/HBoxContainer/Map


func _ready():
	$Copyright.text = Global.version + " - " + Global.author
	
func _process(delta):
	$FlavorText.rect_rotation += 200 * delta
	
	if !$VideoPlayer.is_playing():
		$VideoPlayer.play()

func _on_TestAreaButton_pressed():
	selected_map = maps["TestArea"]
	selected_map_name = "TestArea"
	
	map_text.text = "Map: " + "TestArea"
	
	if Global.game_mode == Global.game_modes.SINGLEPLAYER:
		get_tree().change_scene(selected_map)

func _on_Button_pressed():
	selected_map = maps["Qodot"]
	selected_map_name = "Qodot"
	
	map_text.text = "Map: " + "Qodot"
	
	if Global.game_mode == Global.game_modes.SINGLEPLAYER:
		get_tree().change_scene(selected_map)


func _on_Singleplayer_toggled(button_pressed):
	if button_pressed:
		Global.game_mode = Global.game_modes.SINGLEPLAYER
		
		$ScrollContainer/VBoxContainer/Multiplayer.pressed = false
		$ScrollContainer2.show()
	else:
		Global.game_mode = null
		
		$ScrollContainer2.hide()


func _on_Multiplayer_toggled(button_pressed):
	if button_pressed:
		Global.game_mode = Global.game_modes.MULTIPLAYER
		
		$ScrollContainer/VBoxContainer/Singleplayer.pressed = false
		$ScrollContainer2.show()
		$ScrollContainer/VBoxContainer/Host.show()
		$ScrollContainer/VBoxContainer/Join.show()
	else:
		Global.game_mode = null
		
		$ScrollContainer2.hide()
		$ScrollContainer/VBoxContainer/Host.hide()
		$ScrollContainer/VBoxContainer/Join.hide()


func _on_Host_pressed():
	#if there is a selected map and there isn't a server yet
	if selected_map != null:
		#network.server_info.name = $ScrollContainer2/VBoxContainer/PanelContainer/HBoxContainer/ServerEdit.text
		#network.server_info.max_players = 32
		var port = int($ScrollContainer2/VBoxContainer/PanelContainer/HBoxContainer/PortEdit.text)
		var server_name = $ScrollContainer2/VBoxContainer/PanelContainer/HBoxContainer/ServerEdit.text
	
		# And create the server, using the function previously added into the code
		network.create_server(selected_map, server_name, port)
		
func _on_ready_to_play():
	#selected_map = maps["Qodot"]	#temp
	get_tree().change_scene(selected_map)

func _on_Join_toggled(button_pressed):

	if button_pressed:
		$ScrollContainer2.hide()
		$ScrollContainer/VBoxContainer/IP.show()
		$ScrollContainer/VBoxContainer/Port.show()
		$ScrollContainer/VBoxContainer/JoinServer.show()
	else:
		$ScrollContainer2.show()
		$ScrollContainer/VBoxContainer/IP.hide()
		$ScrollContainer/VBoxContainer/Port.hide()
		$ScrollContainer/VBoxContainer/JoinServer.hide()


func _on_JoinServer_pressed():
	selected_map = null
	var port = int($ScrollContainer/VBoxContainer/Port/HBoxContainer/LineEdit.text)
	var ip = $ScrollContainer/VBoxContainer/IP/HBoxContainer/LineEdit.text
	network.join_server(ip, port)

func _on_Quit_toggled(button_pressed):
	$AcceptDialog.popup_centered()

func _on_AcceptDialog_confirmed():
	get_tree().quit()

func _on_Settings_pressed():
	var settings_node = load("res://scenes/Settings.tscn").instance()
	add_child(settings_node)
