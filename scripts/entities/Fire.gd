extends Spatial

var target = null
var damage_amount = 15				#default damage value

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties():
	if "damage" in properties:
		damage_amount = properties["damage"]
		
func _ready():
	update_properties()

func _on_Area_body_entered(body):
	$Timer.start()
	target = body

func _on_Area_body_exited(body):
	$Timer.stop()
	target = body

func _on_Timer_timeout():
	if target.has_method("damage") and target is KinematicBody:
		target.damage(damage_amount)
