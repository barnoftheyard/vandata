extends Control

var moving = false

var mouse_accel = Vector2()

onready var chat_box = $PanelContainer/VBoxContainer/ChatBox
var chat_text = ""

var player_list = null

func pain():
	$PainOverlay.self_modulate.a = 1
	$VisualNoise.material.set_shader_param("grain_alpha", 0.5)
	
func death(time_remaining):
	$DeathOverlay.show()
	$DeathOverlay/Label.text = time_remaining
	$CenterContainer.hide()
	
func respawn():
	$PlayerName.text = get_parent().player_info["name"]
	$DeathOverlay.hide()
	$CenterContainer.show()

	
func _ready():
	Console.connect_node(self)
	#hack!
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
			if $PanelContainer/VBoxContainer/ChatLine.visible:
				Global.is_paused = false
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				
				$PanelContainer/VBoxContainer/ChatLine.release_focus()
				$PanelContainer/VBoxContainer/ChatLine.hide()
				
				chat_box.get_node("Timer").start()
			else:
				Global.is_paused = true
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				
				$PanelContainer/VBoxContainer/ChatLine.grab_focus()
				$PanelContainer/VBoxContainer/ChatLine.show()
				
				$PanelContainer.modulate.a = 1
				
				chat_box.get_node("Timer").stop()
		
		#The player list UI
		if Input.is_action_just_pressed("ui_tab"):
			$PlayerList.show()
		elif Input.is_action_just_released("ui_tab"):
			$PlayerList.hide()
			
func _process(delta):
	
#	$CenterContainer/Crosshair.position = $CenterContainer/Crosshair.position.linear_interpolate(
#		mouse_accel + $CenterContainer.rect_pivot_offset, 20 * delta
#	)
	
	var weapon = get_parent().weapon
	
	$HealthMeter.value = get_parent().player_info["health"]
	$CenterContainer/Crosshair.frame = Global.game_config["crosshair"]
	
	#The FPS label
	if Global.game_config["show_fps"]:
		$Fps.show()
		$Fps.text = "FPS: " + str(Engine.get_frames_per_second())
	else:
		$Fps.hide()
	
	#if the pain overlay is visible gradually fade it away until it isn't
	if $PainOverlay.self_modulate.a > 0 and !get_parent().is_dead:
		$PainOverlay.self_modulate.a -= delta
		
	var noise = $VisualNoise.material.get_shader_param("grain_alpha")
	if noise > 0:
		$VisualNoise.material.set_shader_param("grain_alpha", noise - delta)
		
	if get_parent().weapon != null:
		#Hud update code
		$AmmoCounter.text = str(weapon.current_ammo)
		$WeaponName.text = weapon.weapon_name
		
		#to make sure the counters don't display "null" as a string
		if weapon.current_clip != null:
			$ClipCounter.text = str(weapon.current_clip)
		else:
			$ClipCounter.text = ""
		if weapon.current_ammo != null:
			$AmmoCounter.text = str(weapon.current_ammo)
		else:
			$AmmoCounter.text = ""
	
	# if our player list doesn't match the network's (something has changed)
	if player_list != network.player_list:
		# remove every name from player list UI (not the best method but it works)
		for child in $PlayerList/VBoxContainer2/Grid.get_children():
			child.queue_free()
		
		# for each player in the network player list, make a new label and set it
		# as a name in the net work player list
		for player in network.player_list:
			var label = Label.new()
			label.text = network.player_list[player]["name"]
			$PlayerList/VBoxContainer2/Grid.add_child(label)
	
	# set out player list to the network's
	player_list = network.player_list


func _on_LineEdit_text_entered(text):
	$PanelContainer/VBoxContainer/ChatLine.clear()
	
	Global.is_paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	$PanelContainer/VBoxContainer/ChatLine.hide()
	
	if text != "":
		rpc("update_chat", text)
		
	chat_box.get_node("Timer").start()

#Update our chat
remotesync func update_chat(new_text):
	var the_text = network.player_list[str(get_tree().get_rpc_sender_id())]["name"] + ": " + new_text
	$PanelContainer/VBoxContainer/ChatBox.text += the_text + '\n'
	$PanelContainer/VBoxContainer/ChatBox.rset("text", the_text + '\n')
	network.console_msg(the_text)
	
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
	chat_box.get_node("AnimationPlayer").stop()
	$PanelContainer.modulate.a = 1
	chat_box.get_node("Timer").start()

func _on_Timer_timeout():
	$PanelContainer/VBoxContainer/ChatBox/AnimationPlayer.play("fadeout")
	
const hud_desc = "Enables/disables the player HUD"
const hud_help = "Enables/disables the player HUD"
func hud_cmd(command):
	visible = bool(int(command))
const say_desc = "Talk through player chat"
const say_help = "Talk through player chat"
func say_cmd(command):
	rpc("update_chat", command)
	
const list_desc = "See player list"
const list_help = "See player list"
func list_cmd():
	print(network.player_list)
	Console.print(network.player_list)


func _on_ChatLine_focus_entered():
	yield(get_tree().create_timer(0.001), "timeout")
	$PanelContainer/VBoxContainer/ChatLine.text = ""
