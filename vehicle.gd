extends RigidBody3D
class_name Vehicle

@export_group("Suspension")
@export var spring_strength : float = 6000.0
@export var damping_strength : float = 300.0
@export var suspension_rest_length : float = 0.6
@export_group("Engine")
@export var engine_force : float = 100.0
@export var max_speed : float = 30.0


@onready var wheels = [
	$WheelRaycasts/RightFrontWheel,
	$WheelRaycasts/LeftFrontWheel,
	$WheelRaycasts/RightBackWheel,
	$WheelRaycasts/LeftBackWheel
]

func _physics_process(delta):
	var throttle := Input.get_action_strength("drive_accelerate")
	
	for wheel in wheels:
		apply_suspension_force(wheel)
		#apply_wheel_torque(wheel, throttle)

func wheel_raycast(wheel : RayCast3D):
	var origin = wheel.global_transform.origin
	var ray_end = origin + to_global(wheel.target_position)
	var query = PhysicsRayQueryParameters3D.create(origin, ray_end)
	query.collide_with_areas = true
	query.exclude = [self]

	return get_world_3d().direct_space_state.intersect_ray(query)

func apply_suspension_force(wheel : RayCast3D):
	if not wheel.is_colliding():
		return

	var hit_position = wheel.get_collision_point()
	var wheel_origin = wheel.global_transform.origin

	# Distance between suspension point and ground
	var current_length = wheel_origin.distance_to(hit_position)
	var compression = suspension_rest_length - current_length
	compression = clamp(compression, 0.0, suspension_rest_length)

	# Get velocity at the wheel position
	var offset = wheel_origin - global_transform.origin
	var point_velocity = linear_velocity + angular_velocity.cross(offset)
	var vertical_velocity = point_velocity.dot(global_transform.basis.y)

	# Hooke's law + damping
	var force = (compression * spring_strength) - (vertical_velocity * damping_strength)

	if force > 0.0:
		apply_force(global_transform.basis.y * force, to_local(wheel_origin))
#
#func apply_wheel_torque(wheel : RayCast3D, throttle : float):
	#if not wheel_raycast(wheel):
		#return
	## Local forward direction of the vehicle
	#var forward := -global_transform.basis.z
#
	## Current speed in the forward direction
	#var speed := linear_velocity.dot(forward)
#
	## Limit max speed
	#if abs(speed) < max_speed or sign(speed) != sign(throttle):
		#var force := forward * throttle * engine_force
		#apply_force(force, to_local(wheel.global_transform.origin))
