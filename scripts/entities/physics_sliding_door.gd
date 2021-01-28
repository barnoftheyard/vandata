extends KinematicBody
tool

signal open
signal close
signal toggle

var offset = Vector3()
var direction = Vector3()
var distance = 0.0
var time = 0.0
var speed = 1.0
var interp = 0

enum states {OPEN, CLOSE}
var state = null

onready var init_pos = self.translation

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()
		
func bullet_hit(_damage, _id, _bullet_hit_pos, _force_multiplier):			#handles how bullets push the prop
	if "open_on_damage" in properties and properties["open_on_damage"] > 0:
		emit_signal("open")
		
func move(object, b, t):
	match interp:
		0:
			return object.move_toward(b, t)
		1:
			return object.linear_interpolate(b, t)
		_:
			return object.move_toward(b, t)

func update_properties():
	if "offset" in properties:
		offset = properties["offset"]
	if "direction" in properties:
		direction = properties["direction"]
	if "distance" in properties:
		distance = properties["distance"]
	if "time" in properties:
		time = properties["time"]
	if "speed" in properties:
		speed = properties["speed"]
	if "interp" in properties:
		interp = properties["interp"]
		
func _ready():
	connect("open", self, "_on_open")
	connect("close", self, "_on_close")
	connect("toggle", self, "_on_toggle")

func use():
	emit_signal("toggle")

func _on_open():
	state = states.OPEN
	
	if time > 0:
		yield(get_tree().create_timer(time), "timeout")
		state = states.CLOSE
		
func _on_close():
	state = states.CLOSE
	
func _on_toggle():
	if state == states.OPEN:
		state = states.CLOSE
	elif state == states.CLOSE:
		state = states.OPEN
	else:
		state = states.OPEN
	
func _physics_process(delta):
	match state:
		states.OPEN:
			self.translation = move(
				self.translation, 
				(init_pos + direction.normalized() * (distance / 16)) + offset, 
				delta * speed
			)
				#1 godot unit = 16 trenchbroom units
		states.CLOSE:
			self.translation = move(
				self.translation, 
				init_pos, 
				delta * speed
			)
