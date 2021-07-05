extends QodotEntity

var pressed = false
var base_translation = Vector3.ZERO
var angle := 0.0
var speed := 8.0
var depth := 0.8
var wait := 0.1
var delay :=  0.1

signal trigger

func _ready() -> void:
	if 'angle' in properties:
		angle = properties['angle']

	if 'speed' in properties:
		speed = properties['speed']

	if 'depth' in properties:
		depth = properties['depth']

	if 'wait' in properties:
		wait = properties['wait']

	if 'delay' in properties:
		delay = properties['delay']

	base_translation = translation

	var children := get_children()
	if children.size() > 0:
		var physics_body = children[0]
		if physics_body is PhysicsBody:
			physics_body.connect("input_event", self, "unhandled_input")

func _process(delta: float) -> void:
	var target_position = base_translation + (Vector3.FORWARD.rotated(Vector3.UP, deg2rad(-angle)) * (depth if pressed else 0.0))
	translation = translation.linear_interpolate(target_position, speed * delta)

func unhandled_input(camera: Node, event: InputEvent, click_position: Vector3, click_normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if BUTTON_LEFT & event.button_mask == BUTTON_LEFT:
			use()

func use():
	if pressed:
		return

	pressed = true
	if wait > 0:
		yield(get_tree().create_timer(wait), "timeout")
		release()

	fire_pressed()

func fire_pressed():
	if delay > 0:
		yield(get_tree().create_timer(delay), "timeout")
	emit_signal("trigger")


func release():
	if not pressed:
		return

	pressed = false
