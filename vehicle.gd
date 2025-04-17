extends RigidBody3D
class_name Vehicle

@export_group("Suspension")
@export var spring_strength: float = 3000.0
@export var damping_strength: float = 50.0
@export var suspension_rest_length: float = 0.6

@export_group("Engine")
@export var engine_force: float = 100.0
@export var max_speed: float = 30.0
@export var traction_factor: float = 0.7  # New variable to control wheel grip

@onready var wheels = [
	$WheelRaycasts/RightFrontWheel,
	$WheelRaycasts/LeftFrontWheel,
	$WheelRaycasts/RightBackWheel,
	$WheelRaycasts/LeftBackWheel
]

func _physics_process(delta):
	var throttle := Input.get_action_strength("drive_accelerate") - Input.get_action_strength("drive_brake")
	
	for wheel in wheels:
		apply_suspension_force(wheel)
		apply_wheel_torque(wheel, throttle)

func wheel_raycast(wheel: RayCast3D):
	# Use built-in RayCast functionality to get more reliable results
	if wheel.is_colliding():
		return {
			"position": wheel.get_collision_point(),
			"normal": wheel.get_collision_normal(),
			"collider": wheel.get_collider()
		}
	return null

func apply_suspension_force(wheel: RayCast3D):
	var result = wheel_raycast(wheel)
	if not result:
		return
		
	var origin = wheel.global_transform.origin
	var contact = result.position
	var normal = result.normal
	
	# Calculate hit distance along the suspension direction (wheel's -Y axis)
	var suspension_dir = -wheel.global_transform.basis.y.normalized()
	var hit_vector = contact - origin
	var hit_distance = hit_vector.length()
	
	# Calculate suspension compression
	var compression = suspension_rest_length - hit_distance
	compression = clamp(compression, 0.0, suspension_rest_length)
	
	# Calculate the offset from the center of mass to the wheel
	var offset = wheel.global_transform.origin - global_transform.origin
	
	# Get velocity at the wheel point
	var point_velocity = linear_velocity + angular_velocity.cross(offset)
	
	# Project velocity onto suspension direction
	var suspension_velocity = point_velocity.dot(suspension_dir)
	
	# Calculate spring force (compression) and damping force (velocity)
	var spring_force = spring_strength * compression
	var damping_force = damping_strength * suspension_velocity
	
	# Total force along suspension direction
	var total_force = (spring_force - damping_force)
	
	if compression > 0:
		# Apply force opposite to suspension direction (upward)
		apply_force(-suspension_dir * total_force, origin)
		
		## Apply normal force to prevent sliding on slopes
		#apply_force(normal * total_force * 0.3, origin)

func apply_wheel_torque(wheel: RayCast3D, throttle: float):
	var result = wheel_raycast(wheel)
	if not result:
		return
		
	# Local forward direction of the vehicle
	var forward = -global_transform.basis.z.normalized()
	
	# Current speed in the forward direction
	var speed = linear_velocity.dot(forward)
	
	# Throttle force calculation
	var force_magnitude = 0.0
	if abs(speed) < max_speed or sign(speed) != sign(throttle):
		force_magnitude = throttle * engine_force
	
	# Apply driving force at wheel position
	var driving_force = forward * force_magnitude
	apply_force(driving_force, wheel.global_transform.origin)
	
	# Calculate lateral velocity for traction control
	var right = global_transform.basis.x.normalized()
	var lateral_velocity = linear_velocity.dot(right)
	
	# Apply counter force to reduce lateral sliding (simulates tire grip)
	var traction_force = -right * lateral_velocity * traction_factor
	apply_force(traction_force, wheel.global_transform.origin)

func _ready():
	# Make sure all wheel raycasts are enabled and set to proper length
	for wheel in wheels:
		wheel.enabled = true
		wheel.target_position = Vector3(0, -suspension_rest_length * 1.5, 0)
