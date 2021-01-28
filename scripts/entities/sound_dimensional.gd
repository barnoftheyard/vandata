extends AudioStreamPlayer3D
tool

signal play
signal stop
signal toggle

var path = null
var loop = false

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties():
	if "path" in properties:
		path = properties["path"]
	if "loop" in properties and properties["loop"] > 0:
		loop = true
	if "autoplay" in properties and properties["autoplay"] > 0:
		autoplay = true
		
func _ready():
	connect("play", self, "_on_play")
	connect("stop", self, "_on_stop")
	connect("toggle", self, "_on_toggle")
	
	if path != null:
		var ext = path.right(path.length() - 4)
		print(ext)
		if ext == ".wav" or ext == ".ogg":
			load(path)
			emit_signal("play")

func _on_play():
	play()
		
func _on_stop():
	stop()
	
func _on_toggle():
	if playing:
		stop()
	elif !playing:
		play()
