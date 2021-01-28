extends RigidBody
tool

signal bounce

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()
		
func bullet_hit(damage, _id, bullet_hit_pos, force_multiplier):			#handles how bullets push the prop
	var direction_vect = global_transform.origin - bullet_hit_pos
	direction_vect = direction_vect.normalized()
	apply_impulse(bullet_hit_pos, direction_vect * (mass / (damage * force_multiplier)))

func update_properties():
	if 'velocity' in properties:
		linear_velocity = properties['velocity']
		
func _ready():
	connect("bounce", self, "_on_bounce")

func use():
	emit_signal("bounce")

func _on_bounce():
	linear_velocity.y = 10
