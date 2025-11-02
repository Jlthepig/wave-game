extends CharacterBody3D

@export_category("Movement")
@export var SPEED : float = 5.0
@export var JUMP_VELOCITY : float = 4.5

@export_category("Mouse")
@export var sensitivity: float = 0.1
@export var min_pitch: float = -89.0
@export var max_pitch: float = 89.0
var mouse_locked: bool = true
var pitch: float = 0.0

@export_category("Camera")
@export var Camera: Camera3D

@export_category("Head Bob")
@export var bob_freq: float = 2.0  # Frequency of head bob
@export var bob_amp: float = 0.08  # Amplitude of head bob
@export var breathing_freq: float = 0.3  # Breathing frequency (slower)
@export var breathing_amp: float = 0.02  # Breathing amplitude (subtle)

var bob_time: float = 0.0
var breathing_time: float = 0.0
var camera_origin: Vector3

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Camera:
		camera_origin = Camera.position

func _input(event):
	if event is InputEventMouseMotion and mouse_locked:
		# Rotate character body horizontally (yaw)
		rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		
		# Rotate camera vertically (pitch)
		pitch -= event.relative.y * sensitivity
		pitch = clamp(pitch, min_pitch, max_pitch)
		Camera.rotation_degrees.x = pitch

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		mouse_locked = !mouse_locked
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if not mouse_locked else Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_moving = direction.length() > 0 and is_on_floor()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	# Apply head bob
	if Camera:
		apply_head_bob(delta, is_moving)

func apply_head_bob(delta: float, is_moving: bool) -> void:
	var bob_offset = Vector3.ZERO
	
	if is_moving:
		# Walking head bob
		bob_time += delta * bob_freq
		bob_offset.y = sin(bob_time * TAU) * bob_amp
		bob_offset.x = cos(bob_time * TAU * 0.5) * bob_amp * 0.5
	else:
		# Idle breathing
		breathing_time += delta * breathing_freq
		bob_offset.y = sin(breathing_time * TAU) * breathing_amp
		
		# Smoothly reset bob_time when stopping
		bob_time = lerp(bob_time, 0.0, delta * 5.0)
	
	# Apply the offset
	Camera.position = camera_origin + bob_offset
