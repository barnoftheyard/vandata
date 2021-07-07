class_name Ladder
extends StaticBody

var captured = false
var player_node = null

func use(player):
	if player is Player:
		captured = !captured
		player_node = player
		
		player_node.is_on_ladder = true
		player_node.weapon.put_away_weapon()
		player_node.vel.y = 0
		
func _physics_process(delta):
	if player_node != null:
		if captured:
			
			var x = self.global_transform.origin
			#get the second child's shape (which in qodot is always the CollisionShape)
			var y = get_child(1).shape.extents
			
			var a = Vector3(x.x, x.y - y.y, x.z)
			var b = player_node.global_transform.origin
			var c = Vector3(x.x, x.y + y.y, x.z)
			
			#if the distance from the player, to the bottom is greater than the
			#hypotenuse of the walls of the ladder's shape and the player is lower
			#than the top of the ladder, go to the bottom
			if b.distance_to(a) >= sqrt(y.x * y.x + y.z * y.z) and b.y < c.y:
				var vel = (a - b).normalized()
				vel.y = 0
				player_node.move_and_slide(vel * player_node.speed * 4)
			#if we are higher than the top of the ladder
			elif b.y > c.y:
				captured = false
				player_node.is_on_ladder = false
		else:
			player_node.is_on_ladder = false
			player_node.weapon.bring_out_weapon()
			player_node = null
