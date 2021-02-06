extends Area

#the available weapons to pick up
var weapons = ["pistol", "smg2", "br", "double barrel", "frag"]

export var to_load = ""

var weapon = null
var spinny = null

signal update_weapon_list

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
		
		spinny.rotate_x(deg2rad(35))
	
func _physics_process(delta):
	#spin our model
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
			var difference =  str(target.weapons[to_load]["ammo"] * 1.25 - 
			target.weapons[to_load]["ammo"])
			
			target.weapons[to_load]["ammo"] *= 1.25
			
			print("ammo added: ", difference)
			body.get_node("Hud/VBoxContainer/ChatBox").text += "ammo added: " + difference + "\n"
		#if we don't have the weapon, add it
		else:
				
			our_weapon.hide()
			
			#add a timer if we need to
			if to_load == "smg2":
				our_weapon.add_child(add_timer(0.1))
			elif to_load == "br":
				our_weapon.add_child(add_timer(0.1))
			elif to_load == "pistol":
				our_weapon.translation.y -= 0.5
				
			#add our weapon to our specific player
			#if its ourself
			
			target.hitscan.add_child(our_weapon)
			
			if is_network_master():
				#print to ourselves
				print("weapon picked up: ", to_load)
				body.get_node("Hud/VBoxContainer/ChatBox").text += "weapon picked up: " + to_load + "\n"
				
				$pickup.play()
			
			#emit a signal to our weapon node to update the weapon list data
			emit_signal("update_weapon_list")
			#switch to our weapon
			target.switch_to_weapon(to_load)
				
		
		$CollisionShape.disabled = true
		hide()

func _on_pickup_finished():
	queue_free()
