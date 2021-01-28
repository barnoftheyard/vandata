class_name PhysBrush
extends PhysicsEntity

const IS_PHYSBRUSH = true

var targets = []
var last_body = null

var metal_sounds = []

func _on_body_entered(body):			#get all bodies (that are kine or rigid) that are in area
	#make sure that the object we get isn't one that we got before last time
	if (body is KinematicBody or body is RigidBody or body is StaticBody or 
	body.has_method("IS_PHYSBRUSH") and last_body != body):
		targets.append(body)
		last_body = body
	
func _ready():
	#get all wav files in folder
	metal_sounds = Global.files_in_dir("res://sounds/metal/", ".wav")
	
	continuous_cd = true
	contact_monitor = true
	contacts_reported = 4
	connect("body_entered", self, "_on_body_entered")
	
	#add our sound impact node
	var sound = AudioStreamPlayer3D.new()
	sound.name = "impact"
	sound.max_db = 6
	add_child(sound)

func update_properties():
		
	if "sleeping" in properties:
		if properties["sleeping"] > 0:
			sleeping = true
		else:
			sleeping = false
	if "mass" in properties:
		mass = properties["mass"]
		
func _physics_process(delta):
	if targets.size() > 0:
		for x in targets:
			Global.play_rand($impact, metal_sounds)
		#reset target list
		targets = []
		last_body = null
		
func bullet_hit(damage, _id, bullet_hit_pos, force_multiplier):			#handles how bullets push the prop
	var direction_vect = global_transform.origin - bullet_hit_pos
	direction_vect = direction_vect.normalized()
	apply_impulse(bullet_hit_pos, direction_vect * (mass / (damage * force_multiplier)))

	Global.play_rand($impact, metal_sounds)
