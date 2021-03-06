extends Area

#the available weapons to pick up
var weapons = ["pistol", "smg2", "br", "double barrel", "frag"]

export var to_load = ""
export var remove_on_pickup = false

var weapon = null
var spinny = null

var muzzle_flash = preload("res://scenes/Weapons/muzzle_flash.tscn")

signal update_weapon_list

func set_all_meshes_layer_mask(node, value):
	for n in node.get_children():
		if n.get_child_count() > 0:
			set_all_meshes_layer_mask(n, value)
		if n is MeshInstance:
			n.set_layer_mask(value)
			n.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF

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
		add_child(spinny)
		
		if to_load == "frag":
			spinny.scale *= 0.25
		elif to_load == "pistol":
			spinny.scale *= 0.75
		
		spinny.rotate_x(deg2rad(35))
	
func _physics_process(delta):
	#spin our model
	if spinny != null:
		spinny.rotate_y(delta)
	
		#bounce the model up and down
		var pulse = cos(Global.delta_time * 2) * 0.005
		spinny.translation.y += pulse

func add_timer(time):
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = time
	timer.name = "Timer"
	
	return timer

func _on_WeaponPickup_body_entered(body):
	if body is Player and body.has_node("Camera/Weapon") and weapon != null:
		
		$pickup.play()
		
		var target = body.get_node("Camera/Weapon")
		connect("update_weapon_list", target, "_on_update_weapon_list")
		var our_weapon = null
		
		if to_load == "frag":
			our_weapon = load("res://scenes/weapons/grenade.tscn").instance()
		else:
			our_weapon = weapon.instance()
		
		#if we already have the weapon in our inventory, add more ammo instead
		#of another weapon
		if target.hitscan.has_node(to_load):
			var difference = (target.weapons[to_load]["clip"] + 
			target.weapons[to_load]["times_fired"]) * 2
			
			target.weapons[to_load]["ammo"] += difference
			
			print(to_load, " Ammo added: ", difference)
			body.get_node("Hud").chat_box.text += to_load + " ammo added: " + str(difference) + "\n"
		#if we don't have the weapon, add it
		else:
				
			our_weapon.hide()
			
			var m = muzzle_flash.instance()
			
			#This is where we construct the full weapon for our weapon node to use
			#A lot of tweaks are done here, such as timers, muzzle flashes, model moving
			if to_load == "smg2":
				our_weapon.add_child(add_timer(0.1))
			elif to_load == "br":
				our_weapon.add_child(add_timer(0.1))
				
				our_weapon.add_child(m)
				m.translation = Vector3(0, 0.12, -1.3)
				m.scale /= 1.5
			elif to_load == "pistol":
				our_weapon.translation.y -= 0.5
				
				our_weapon.add_child(m)
				m.translation = Vector3(0, 0.5, -0.8)
				m.scale /= 2
				
				
			set_all_meshes_layer_mask(our_weapon, 2)
			#add our weapon to our specific player
			#if its ourself
			
			target.hitscan.add_child(our_weapon)
			
			if is_network_master():
				#print to ourselves
				print("Weapon picked up: ", to_load)
				body.get_node("Hud").chat_box.text += "Weapon picked up: " + to_load + "\n"
				
			
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
