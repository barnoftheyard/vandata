extends Control

var chat_box = false
var moving = false

var mouse_accel = Vector2()

func pain():
	$PainOverlay.self_modulate.a = 1
	
func death(time_remaining):
	$DeathOverlay.show()
	$DeathOverlay/Label.text = "RESPAWN: " + time_remaining
	$CenterContainer.hide()
	
func respawn():
	$PlayerName.text = get_parent().player_info["name"]
	$DeathOverlay.hide()
	$CenterContainer.show()

	
func _ready():
	Console.connect_node(self)
	#network.connect("player_list_changed", self, "_on_player_list_changed")
	#list_change()
	
func _input(event):
	if !Global.is_paused:
		
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			mouse_accel = -event.relative
			moving = true
		else:
			moving = false
			
		#Pop up the chat window
		if Input.is_action_just_pressed("ui_chat"):
			if $ChatLine.has_focus() and $ChatLine.visible:
				Global.is_paused = false
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				
				$ChatLine.hide()
			else:
				Global.is_paused = true
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				
				$ChatLine.show()
				$ChatLine.text = ""
				$ChatLine.grab_focus()
		
		#The player list UI
		if Input.is_action_just_pressed("ui_tab"):
			$PlayerList.show()
		elif Input.is_action_just_released("ui_tab"):
			$PlayerList.hide()
			
func _process(delta):
	
#	$CenterContainer/Crosshair.position = $CenterContainer/Crosshair.position.linear_interpolate(
#		mouse_accel + $CenterContainer.rect_pivot_offset, 20 * delta
#	)
	
	if $PainOverlay.self_modulate.a > 0:
		$PainOverlay.self_modulate.a -= 1 * delta
	
	var weapon = get_parent().weapon
	
	$HealthMeter.value = get_parent().player_info["health"]
	$CenterContainer/Crosshair.frame = Global.game_config["crosshair"]
	
	if Global.game_config["show_fps"]:
		$Fps.show()
		$Fps.text = "FPS: " + str(Engine.get_frames_per_second())
	else:
		$Fps.hide()
	
	if $PainOverlay.self_modulate.a != 0:
		$PainOverlay.self_modulate.a -= delta
		
	#Hud update code
	$AmmoCounter.text = str(weapon.current_ammo)
	$WeaponName.text = weapon.weapon_name
	
	if weapon.current_clip != null:
		$ClipCounter.text = str(weapon.current_clip)
	else:
		$ClipCounter.text = ""
	if weapon.current_ammo != null:
		$AmmoCounter.text = str(weapon.current_ammo)
	else:
		$AmmoCounter.text = ""


func _on_LineEdit_text_entered(text):
	$ChatLine.clear()
	
	Global.is_paused = false
	chat_box = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	$ChatLine.hide()
	
	rpc("update_chat", text)

#Update our chat
remotesync func update_chat(new_text):
	#$ChatBox.text += str(get_tree().get_rpc_sender_id()) + ": " + new_text + '\n'
	print(get_node("/root/characters/" + str(get_tree().get_rpc_sender_id())).player_info["name"]
	 + ": " + new_text) 
	
#func list_change():
#	for c in $PlayerList/VBoxContainer2/Grid.get_children():
#		c.queue_free()
#
#	# Now iterate through the player list creating a new entry into the boxList
#	for p in network.players:
#		var nlabel = Label.new()
#		nlabel.text = str(network.players[p].name)
#		$PlayerList/VBoxContainer2/Grid.add_child(nlabel)
#
#func _on_player_list_changed():
#	list_change()


func _on_ChatBox_draw():
	$ChatBox/Timer.start()
	$ChatBox.modulate = Color(1, 1, 1, 1)

func _on_Timer_timeout():
	$ChatBox/AnimationPlayer.play("fadeout")
	
const hud_desc = "Enables/disables the player HUD"
const hud_help = "Enables/disables the player HUD"
func hud_cmd():
	visible = !visible

const say_desc = "Talk through player chat"
const say_help = "Talk through player chat"
func say_cmd(command):
	rpc("update_chat", command)
