extends RigidBody3D
class_name Vehicle

# Wheel nodes (you can also export them if you like)
@onready var wheels = [
	$WheelRaycasts/RightFrontWheel,
	$WheelRaycasts/LeftFrontWheel,
	$WheelRaycasts/RightBackWheel,
	$WheelRaycasts/LeftBackWheel
]

# How far down to cast the ray (like suspension length)
var raycast_length := .6
var spring_strength := 4000.0
var damping_strength := 300.0

func _physics_process(delta):
	for wheel in wheels:
		apply_suspension_force(wheel)

func apply_suspension_force(wheel: Node3D):
	var origin = wheel.global_transform.origin
	var ray_end = origin - Vector3.UP * raycast_length
	var query = PhysicsRayQueryParameters3D.create(origin, ray_end)
	query.collide_with_areas = true
	query.exclude = [self]

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)

	if result:
		var hit_position = result.position
		var distance = origin.y - hit_position.y
		var compression = clamp(1.0 - (distance / raycast_length), 0.0, 1.0)

		# Get point velocity of the vehicle at the wheel position
		var point_velocity = linear_velocity + angular_velocity.cross(origin - global_transform.origin)
		var vertical_velocity = point_velocity.dot(Vector3.UP)

		# Spring force: F = -kx - bv (Hooke’s Law + damping)
		var spring_force = (spring_strength * compression) - (damping_strength * vertical_velocity)

		# Apply upward force only if spring is compressed
		if spring_force > 0.0:
			apply_force(Vector3.UP * spring_force, origin)

