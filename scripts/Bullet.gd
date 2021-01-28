extends RigidBody

var BULLET_DAMAGE = 15

var hit_something = false
var shrink = false

func _ready():
	connect("body_entered", self, "collided")
		
func collided(body):
	if body.has_method("bullet_hit"):
		body.bullet_hit(BULLET_DAMAGE, translation.normalized(), 0.5)
		queue_free()
			
	hit_something = true
	
func _physics_process(delta):
	if hit_something:
		$Trail3D.scale -= Vector3(delta, delta, delta) * 4
		if $Trail3D.scale.x <= 0:
			queue_free()

func _on_Timer_timeout():
	queue_free()

func _on_Timer2_timeout():
	$Trail3D.show()
