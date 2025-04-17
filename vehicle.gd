extends RigidBody3D
class_name Vehicle

@export_group("Suspension")
@export var spring_strength : float = 6000.0
@export var damping_strength : float = 500.0
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

func _physics_process(_delta):
	var throttle := Input.get_action_strength("drive_accelerate")
	
	for wheel in wheels:
		apply_suspension_force(wheel)
		apply_wheel_torque(wheel, throttle)

func wheel_raycast(wheel: RayCast3D):
	var origin = wheel.global_transform.origin
	var ray_end = origin + -wheel.global_transform.basis.y * wheel.target_position.length()  # Downward ray

	var query = PhysicsRayQueryParameters3D.create(origin, ray_end)
	query.collide_with_areas = true
	query.exclude = [self]

	return get_world_3d().direct_space_state.intersect_ray(query)


func apply_suspension_force(wheel: RayCast3D):
	var result = wheel_raycast(wheel)
	if not result:
		return

	var origin = wheel.global_transform.origin
	var contact = result.position

	var hit_distance = origin.distance_to(contact)
	var compression = suspension_rest_length - hit_distance
	compression = clamp(compression, 0.0, suspension_rest_length)

	# SAFELY compute world-space offset from center of mass to wheel
	var offset = origin - global_transform.origin

	# Get velocity at the point on the rigid body
	var world_point_velocity = linear_velocity + angular_velocity.cross(offset)
	var upward_dir = global_transform.basis.y.normalized()
	var vertical_velocity = world_point_velocity.dot(upward_dir)

	var spring_force = (spring_strength * compression) - (damping_strength * vertical_velocity)

	if spring_force > 0.0:
		apply_force(upward_dir * spring_force, origin)


func apply_wheel_torque(wheel : RayCast3D, throttle : float):
	if not wheel_raycast(wheel):
		return
	# Local forward direction of the vehicle
	var forward := -global_transform.basis.z

	# Current speed in the forward direction
	var speed := linear_velocity.dot(forward)

	# Limit max speed
	if abs(speed) < max_speed or sign(speed) != sign(throttle):
		var force := forward * throttle * engine_force
		apply_force(force, wheel.global_transform.origin)
