extends RigidBody3D

@export var spring_strength := 5000.0
@export var damping := 300.0
@export var rest_length := 0.5

@onready var ray := $SuspensionRay

func _physics_process(delta):
	if not ray.is_colliding():
		return

	var hit_position = ray.get_collision_point()
	var wheel_origin = ray.global_transform.origin

	# Distance between suspension point and ground
	var current_length = wheel_origin.distance_to(hit_position)
	var compression = rest_length - current_length
	compression = clamp(compression, 0.0, rest_length)

	# Get velocity at the wheel position
	var offset = wheel_origin - global_transform.origin
	var point_velocity = linear_velocity + angular_velocity.cross(offset)
	var vertical_velocity = point_velocity.dot(global_transform.basis.y)

	# Hooke's law + damping
	var force = (compression * spring_strength) - (vertical_velocity * damping)

	if force > 0.0:
		apply_force(global_transform.basis.y * force, to_local(wheel_origin))
