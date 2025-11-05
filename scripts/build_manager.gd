extends Node3D
@export var camera: Camera3D
@export var build_preview_scene: PackedScene = preload("res://Prefabs/building/build_preview.tscn")
@export var floor_scene: PackedScene = preload("res://Prefabs/building/Floor.tscn")
@export var wall_scene: PackedScene = preload("res://Prefabs/building/Wall.tscn")
@export var stair_scene: PackedScene = preload("res://Prefabs/building/Stairs.tscn")

# Grid snapping settings
@export var grid_size: float = 2.0
@export var rotation_snap: float = 90.0  # Degrees per rotation step
@export var snap_to_edge: bool = true  # Snap to grid edges instead of centers
@export var max_build_distance: float = 20.0  # Max distance from camera to build

var current_build_scene: PackedScene = null
var preview: Node3D
var can_build := false
var current_piece_cost := {}
var player_inventory: Dictionary
var current_rotation: float = 0.0  # Current rotation in degrees

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func set_inventory(inv: Dictionary):
	player_inventory = inv

func _input(event):
	if event.is_action_pressed("build_floor"):
		start_build_mode(floor_scene)
	elif event.is_action_pressed("build_wall"):
		start_build_mode(wall_scene)
	elif event.is_action_pressed("build_stairs"):
		start_build_mode(stair_scene)
	elif event.is_action_pressed("cancel_build"):
		end_build_mode()
	elif event.is_action_pressed("place_build") and preview:
		try_place_build()
	
	# Rotation controls (only when in build mode)
	if preview:
		if event.is_action_pressed("rotate_clockwise"):
			rotate_preview(rotation_snap)
		elif event.is_action_pressed("rotate_counter_clockwise"):
			rotate_preview(-rotation_snap)

func start_build_mode(scene: PackedScene):
	current_build_scene = scene
	current_rotation = 0.0  # Reset rotation when starting new build
	
	if preview:
		preview.queue_free()
	
	preview = build_preview_scene.instantiate()
	add_child(preview)
	var dummy = current_build_scene.instantiate()
	var mesh = dummy.get_node_or_null("MeshInstance3D")
	if mesh:
		preview.set_mesh(mesh.mesh)
	current_piece_cost = dummy.cost
	dummy.queue_free()

func end_build_mode():
	if preview:
		preview.queue_free()
		preview = null
	current_build_scene = null
	current_rotation = 0.0

func rotate_preview(angle: float):
	current_rotation += angle
	# Normalize to 0-360 range
	current_rotation = fmod(current_rotation, 360.0)
	if current_rotation < 0:
		current_rotation += 360.0
	
	print("Rotation: ", current_rotation, "°")
	
	if preview:
		var mesh_node = preview.get_node_or_null("Mesh")
		if mesh_node:
			mesh_node.rotation_degrees.y = current_rotation
		else:
			preview.rotation_degrees.y = current_rotation

func _process(delta):
	if not preview:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var space_state = get_world_3d().direct_space_state
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 100
	
	# Create ray query parameters for Godot 4
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	var pos: Vector3
	
	if result:
		# Hit something - use that position
		pos = result.position
	else:
		# Nothing hit - project onto an invisible grid at a fixed distance
		var ray_direction = camera.project_ray_normal(mouse_pos)
		pos = from + ray_direction * max_build_distance
	
	# Snap to grid
	if snap_to_edge:
		# Snap to grid edges/corners (floor to nearest grid line)
		pos.x = floor(pos.x / grid_size) * grid_size
		pos.y = floor(pos.y / grid_size) * grid_size
		pos.z = floor(pos.z / grid_size) * grid_size
	else:
		# Snap to grid centers (round to nearest grid point)
		pos = pos.snapped(Vector3(grid_size, grid_size, grid_size))
	
	preview.global_position = pos
	
	# Maintain rotation every frame - rotate the Mesh child node
	var mesh_node = preview.get_node_or_null("Mesh")
	if mesh_node:
		mesh_node.rotation_degrees.y = current_rotation
	else:
		preview.rotation_degrees.y = current_rotation
	
	can_build = has_enough_resources(current_piece_cost)
	preview.set_valid(can_build)

func try_place_build():
	if not can_build:
		print("❌ Not enough resources!")
		return
	
	var new_build = current_build_scene.instantiate()
	new_build.global_position = preview.global_position
	new_build.rotation_degrees.y = current_rotation  # Apply rotation to placed piece
	get_tree().current_scene.add_child(new_build)
	consume_resources(current_piece_cost)
	print("✅ Built structure at rotation: ", current_rotation, "°")

func has_enough_resources(cost: Dictionary) -> bool:
	for res in cost.keys():
		if player_inventory.get(res, 0) < cost[res]:
			return false
	return true

func consume_resources(cost: Dictionary):
	for res in cost.keys():
		player_inventory[res] -= cost[res]
