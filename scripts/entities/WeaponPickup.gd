extends Area

#the available weapons to pick up
var weapons = ["pistol", "smg", "br", "double barrel", "grenade", "bow", "shovel"]

export var to_load = ""
export var remove_on_pickup = false

var weapon = null
var spinny = null

signal update_weapon_list

func set_all_meshes_layer_mask(node, value):
	for n in node.get_children():
		if n.get_child_count() > 0:
			set_all_meshes_layer_mask(n, value)
		if n is MeshInstance:
			n.set_layer_mask(value)
			n.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF

#func create_collision(node):
#	var has_created = false
#
#	for n in node.get_children():
#		if n.get_child_count() > 0:
#			create_collision(n)
#		if n is MeshInstance and n.name == "frame":
#			n.create_convex_collison()
#			has_created = true
#
#	if !has_created:
#		var shape = CollisionShape.new()
#		shape.shape = SphereShape
#		shape.transform = node.transform
#		node.add_child(shape)

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties():
	if "weapon" in properties:
		to_load = properties["weapon"]

func _ready():
	if weapons.has(to_load):
		weapon = load("res://models/" + to_load + "/" + to_load + ".glb")
	
		spinny = weapon.instance()
		
		if to_load == "grenade":
			spinny.scale *= 0.15
		elif to_load == "pistol":
			spinny.scale *= 0.75
		elif to_load == "shovel":
			spinny.scale *= 0.4
		elif to_load == "bow":
			spinny.scale *= 0.25
		
		#create_collision(spinny)
		add_child(spinny)
		
		#spinny.rotate_x(deg2rad(35))
	
func _physics_process(delta):
	#spin our model
	if spinny != null:
		spinny.rotate_y(delta)

		#bounce the model up and down
		var pulse = cos(Global.delta_time * 2) * 0.005
		spinny.translation.y += pulse

#Depricated as we just use precreated scenes for weapon adding
#func add_timer(time):
#	var timer = Timer.new()
#	timer.one_shot = true
#	timer.wait_time = time
#	timer.name = "Timer"
#
#	return timer

remotesync func _on_WeaponPickup_body_entered(body):
	if body is Player and body.has_node("Camera/Weapon") and weapon != null:
		
		#rpc_id(int(body.name), "_on_WeaponPickup_body_entered")
		
		$pickup.play()
		
		var target = body.get_node("Camera/Weapon")
		if !is_connected("update_weapon_list", target, "_on_update_weapon_list"):
			connect("update_weapon_list", target, "_on_update_weapon_list")
		var our_weapon = null
		
		if to_load in weapons:
			our_weapon = load("res://scenes/weapons/" + to_load + ".tscn").instance()
		else:
			our_weapon = weapon.instance()
		
		#if we already have the weapon in our inventory, add more ammo instead
		#of another weapon
		if (target.hitscan.has_node(to_load) and to_load != "shovel" 
		and to_load != "grenade"):
			
			var difference = (target.weapons[to_load]["clip"] + 
				target.weapons[to_load]["times_fired"]) * 2
			
			target.weapons[to_load]["ammo"] += difference
			
			print(to_load, " Ammo added: ", difference)
			body.get_node("Hud").chat_box.text += to_load + " ammo added: " + str(difference) + "\n"
			
		elif target.hitscan.has_node(to_load) and to_load == "shovel":
			return
		#if we don't have the weapon already, add it to our player's inventory
		else:
				
			set_all_meshes_layer_mask(our_weapon, 2)
				
				
			if is_network_master():
				#print to ourselves
				print("Weapon picked up: ", to_load)
				body.get_node("Hud").chat_box.text += "Weapon picked up: " + to_load + "\n"
			
			#add our weapon to our specific player
			target.hitscan.rpc_config("add_child", MultiplayerAPI.RPC_MODE_REMOTESYNC)
			target.hitscan.rpc_id(int(body.name), "add_child", our_weapon)
			
			#emit a signal to our weapon node to update the weapon list data
			emit_signal("update_weapon_list")
			#switch to our weapon
			target.switch_to_weapon(to_load)
				
		
		$CollisionShape.disabled = true
		hide()
		$Timer.start()

func _on_Timer_timeout():
	if remove_on_pickup:
		queue_free()
	else:
		$CollisionShape.disabled = false
		show()
