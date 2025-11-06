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
@export var bob_freq: float = 2.0
@export var bob_amp: float = 0.08
@export var breathing_freq: float = 0.3
@export var breathing_amp: float = 0.02

var bob_time: float = 0.0
var breathing_time: float = 0.0
var camera_origin: Vector3

# Inventory
var inventory := {
	"driftwood": 0,
	"WornRope": 0,
}

var current_pickup: Area3D = null

# building
var build_mode : bool = false
var current_piece : String = "floor"  # can be "floor", "wall", "stair"
@onready var build_manager: Node3D = $BuildManager

#animation
@onready var animation_tree: AnimationTree = $Camera3D/fpsarms/AnimationTree


#sfx
const LEATHER_INVENTORYSOUND = preload("uid://bbo3lhug6siq4")
@onready var sfx: AudioStreamPlayer = $Sfx
const LEATHER_INVENTORY = preload("uid://bbo3lhug6siq4")
 
func add_resource(type: String, amount: int):
	inventory[type] = inventory.get(type, 0) + amount
	print("Collected ", type, " → total: ", inventory[type])	
	
	# Update inventory UI
	var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui:
		if build_manager:
			build_manager.set_inventory(inventory)
		inv_ui.update_inventory(inventory)

func has_resources(cost: Dictionary) -> bool:
	for res in cost.keys():
		if inventory.get(res, 0) < cost[res]:
			return false
	return true

func consume_resources(cost: Dictionary):
	for res in cost.keys():
		inventory[res] -= cost[res]
	
	# Update UI after consuming
	var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui:
		inv_ui.update_inventory(inventory)


func play_collect_animation():
	if animation_tree:
		var state_machine = animation_tree.get("parameters/playback")
		state_machine.travel("Collect")
		sfx.stream = LEATHER_INVENTORYSOUND
		sfx.play()
		
func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	build_manager.camera = Camera
	build_manager.set_inventory(inventory)
	
	if Camera:
		camera_origin = Camera.position

func _input(event):
	# Only handle mouse movement if not paused
	if event is InputEventMouseMotion and mouse_locked and not get_tree().paused:
		# Rotate character body horizontally (yaw)
		rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		
		# Rotate camera vertically (pitch)
		pitch -= event.relative.y * sensitivity
		pitch = clamp(pitch, min_pitch, max_pitch)
		Camera.rotation_degrees.x = pitch
		
	if event.is_action_pressed("toggle_build"):
		build_mode = !build_mode
		print("Build mode:", build_mode)

func _process(delta: float) -> void:
	# ESC key for mouse unlock (separate from inventory)
	if Input.is_action_just_pressed("ui_cancel") and not get_tree().paused:
		mouse_locked = !mouse_locked
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if not mouse_locked else Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Don't process movement if paused
	if get_tree().paused:
		return
	
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration
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
