extends Spatial
class_name SignalConnect

var confirmed_emitters = []
var confirmed_targets = []

var siblings = null
var emitter_array = null
var target_array = null 

#I'm honestly suprised I wrote most of this. This is for a Qodot-centric entity
#that links two nodes' signals together
#Keep in mind for some reason that "has_signal" does not work on export, so try
#to find alternative function or make one ourselves
#There's a clever diagram in misc which describes what this powerful entity does

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties():
	if is_inside_tree():
		if "signal" in properties:
			
			siblings = get_parent().get_children()
			emitter_array = properties["emitter"].split(",", true)
			target_array = properties["target"].split(",", true)
			
			if "target" in properties:
				#for all nodes that are siblings to us
				find_target()
			else:
				print("No target given in signal connector!")
				return
				
			if "emitter" in properties:
				find_emitter()
			else:
				print("No emitter given in signal connector!")
				return
		else:
			print("No signal given in signal connector!")
			return
		
func _ready():
	update_properties()
		
func find_target():
	#for every sibling node
	for node in siblings:
		#for target in the array of target strings given
		for target_string in target_array:
			#check if they have names, and if they do, do they match our string?
			if ("properties" in node and node.properties.has("name") and 
			node.properties["name"] == target_string):
				#does the node have the signal we intend to fire?
				if node.has_signal(properties["signal"]):
					confirmed_targets.append(node)
					
	#if confirmed targets size is the same as our requested size,
	#for each node in array, fire its signal
	if confirmed_targets.size() <= 0:
		print("%s Trouble finding all targets! Found none!" % self.name)
	elif confirmed_targets.size() != target_array.size():
		print("%s Trouble finding all targets! Only found: %s" % 
		[self.name, confirmed_targets])
					
					
func find_emitter():
	for node in siblings:
		#for target in the array of target strings given
		for emitter_string in emitter_array:
			#check if they have names, and if they do, do they match our string?
			if ("properties" in node and node.properties.has("name") and 
			node.properties["name"] == emitter_string):
				#does the node have the signal we intend to fire?
				if node.has_signal("trigger"):
					confirmed_emitters.append(node)
					
	if confirmed_emitters.size() <= 0:
		print("%s Trouble finding all emitters! Found none!" % self.name)
	elif confirmed_emitters.size() != emitter_array.size():
		print("%s Trouble finding all emitters! Only found: %s" % 
		[self.name, confirmed_emitters])
					
	for emitter in confirmed_emitters:
		if !emitter.is_connected("trigger", self, "_on_trigger"):
			emitter.connect("trigger", self, "_on_trigger")
					
					
func _on_trigger():
		
	for target in confirmed_targets:
		target.emit_signal(properties["signal"])
