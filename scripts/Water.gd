extends Area

export(float) var buoyancy_factor = 30.0
export(float) var damping_factor = 8.0

var water_density = 997
var target = null

var water_node = null

var buoyancy_dict := {}

func _init():
	connect("body_shape_entered", self, "_on_body_shape_entered")
	connect("body_shape_exited", self, "_on_body_shape_exited")

func _on_body_shape_entered(body_id: int, body: Node, body_shape_idx: int, self_shape_idx: int) -> void:
	target = body
	if body is RigidBody:

		var self_collision_shape = shape_owner_get_owner(shape_find_owner(self_shape_idx))
		var body_collision_shape = body.shape_owner_get_owner(body.shape_find_owner(body_shape_idx))
	
		var self_shape = self_collision_shape.get_shape()
		var body_shape = body_collision_shape.get_shape()
	
		var self_aabb = create_shape_aabb(self_shape)
		var body_aabb = create_shape_aabb(body_shape)
	
		buoyancy_dict[body] = {
			'entry_point': body.global_transform.origin,
			'self_aabb': self_aabb,
			'body_aabb': body_aabb
		}
		
	elif body is KinematicBody and "is_player" in body:
		body.is_inwater = true
	
func _on_body_shape_exited(body_id: int, body: Node, body_shape_idx: int, self_shape_idx: int) -> void:
	if body is RigidBody and body in buoyancy_dict:
		buoyancy_dict.erase(body)
		
	elif body is KinematicBody and "is_player" in body:
		body.is_inwater = false
		
	target = null

func create_shape_aabb(shape: Shape) -> AABB:
	if shape is ConvexPolygonShape:
		return create_convex_aabb(shape)
	elif shape is SphereShape:
		return create_sphere_aabb(shape)

	return AABB()

func create_convex_aabb(convex_shape: ConvexPolygonShape) -> AABB:
	var points = convex_shape.get_points()
	var aabb = null

	for point in points:
		if not aabb:
			aabb = AABB(point, Vector3.ZERO)
		else:
			aabb = aabb.expand(point)

	return aabb

func create_sphere_aabb(sphere_shape: SphereShape) -> AABB:
	return AABB(-Vector3.ONE * sphere_shape.radius, Vector3.ONE * sphere_shape.radius)

func _ready():
	for node in get_children():		#for every mesh child, load the material override
		if node is MeshInstance: 
			node.material_override = load("res://resources/SpatialMaterial/Water.tres")
			water_node = node
			
func _physics_process(delta: float) -> void:
	
	water_node.material_override.uv1_offset.x += 1 * delta
	
	#self.scale.y += 1 * delta
	#self.translation.y = self.translation.y + (self.scale.y / 2) * delta
	
	if is_instance_valid(target) and overlaps_body(target):
		if target is RigidBody:
			for body in buoyancy_dict:
				var buoyancy_data = buoyancy_dict[body]
		
				var self_aabb = buoyancy_data['self_aabb']
				self_aabb.position += global_transform.origin
		
				var body_aabb = buoyancy_data['body_aabb']
				body_aabb.position += body.global_transform.origin
		
				var displacement = self_aabb.end.y - body_aabb.position.y
				body.add_central_force(Vector3.UP * displacement * buoyancy_factor)
				body.add_central_force(Vector3.UP * body.get_linear_velocity().y * -damping_factor)
				
		elif target is KinematicBody:		#if the target is a player/npc
			target.vel.y *= (target.GRAVITY / water_density) * delta * -1
