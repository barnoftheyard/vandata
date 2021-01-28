extends Area
tool

signal signal_fire

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()
		
func _init():
	connect("body_shape_entered", self, "_on_body_shape_entered")
	connect("body_shape_exited", self, "_on_body_shape_exited")

func update_properties():
	pass
	
func _on_body_shape_entered():
	emit_signal("trigger")
