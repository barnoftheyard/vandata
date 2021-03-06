extends Control

onready var children = self.get_children()
var to_close = false


func _on_Player_paused():
	Global.is_paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$Open.play()
	$AnimationPlayer.play("fade")
	
func _on_Player_unpaused():
	Global.is_paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Close.play()
	$AnimationPlayer.play_backwards("fade")
	
func _process(_delta):
	if !Global.is_paused and !$AnimationPlayer.is_playing():
		queue_free()
	
func _on_Resume_pressed():
	Global.is_paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Close.play()
	$AnimationPlayer.play_backwards("fade")
	
func _on_Settings_pressed():
	var settings_node = load("res://scenes/Settings.tscn").instance()
	add_child(settings_node)
	
func _on_Quit_pressed():
	Console.emit_signal("run_command", "exit")

func _on_Disconnect_pressed():
	get_tree().change_scene("res://scenes/Control/Menu.tscn")
	get_node("/root/characters").queue_free()
	get_tree().set_network_peer(null)
	
	Console.emit_signal("open_console")
	network.console_msg("Connection to the server ended.")
