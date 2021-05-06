extends Spatial

var text = ""

signal show(player)

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()
		
func _ready():
	connect("show", self, "_on_show")
	
func update_properties():
	if "text" in properties:
		text = properties["text"]
		
	if "timeout" in properties:
		var timer = Timer.new()
		timer.wait_time = properties["timeout"]
		timer.name = "Timer"
		timer.connect("timeout", self, "_on_timeout")
		
		add_child(timer)
