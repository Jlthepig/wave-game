extends Node3D
@export var camera: Camera3D
@export var floor_preview_scene: PackedScene = preload("uid://casb7jlw876c0")
@export var wall_preview_scene: PackedScene = preload("uid://hxr0c36vfi7n")
@export var stair_preview_scene: PackedScene = preload("uid://dgpol0rixhey3")
@export var floor_scene: PackedScene = preload("res://Prefabs/building/Floor.tscn")
@export var wall_scene: PackedScene = preload("res://Prefabs/building/Wall.tscn")
@export var stair_scene: PackedScene = preload("res://Prefabs/building/Stairs.tscn")

# Grid snapping settings
@export var grid_size: float = 2.0
@export var rotation_snap: float = 90.0
@export var snap_to_edge: bool = true
@export var max_build_distance: float = 20.0

var current_build_scene: PackedScene = null
var current_preview_scene: PackedScene = null
var preview: Node3D
var can_build := false
var current_piece_cost := {}
var player_inventory: Dictionary
var current_rotation: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func set_inventory(inv: Dictionary):
	player_inventory = inv

func _input(event):
	if event.is_action_pressed("build_floor"):
		start_build_mode(floor_scene, floor_preview_scene)
	elif event.is_action_pressed("build_wall"):
		start_build_mode(wall_scene, wall_preview_scene)
	elif event.is_action_pressed("build_stairs"):
		start_build_mode(stair_scene, stair_preview_scene)
	elif event.is_action_pressed("cancel_build"):
		end_build_mode()
	elif event.is_action_pressed("place_build") and preview:
		try_place_build()
	
	if preview:
		if event.is_action_pressed("rotate_clockwise"):
			rotate_preview(rotation_snap)
		elif event.is_action_pressed("rotate_counter_clockwise"):
			rotate_preview(-rotation_snap)

func start_build_mode(build_scene: PackedScene, preview_scene: PackedScene):
	current_build_scene = build_scene
	current_preview_scene = preview_scene
	current_rotation = 0.0
	
	if preview:
		preview.queue_free()
	
	preview = current_preview_scene.instantiate()
	add_child(preview)
	
	var dummy = current_build_scene.instantiate()
	current_piece_cost = dummy.cost
	dummy.queue_free()
	
	print("✓ Started build mode")

func end_build_mode():
	if preview:
		preview.queue_free()
		preview = null
	current_build_scene = null
	current_preview_scene = null
	current_rotation = 0.0

func rotate_preview(angle: float):
	current_rotation += angle
	current_rotation = fmod(current_rotation, 360.0)
	if current_rotation < 0:
		current_rotation += 360.0
	
	print("Rotation: ", current_rotation, "°")

func _process(delta):
	if not preview:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var space_state = get_world_3d().direct_space_state
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 100
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	var pos: Vector3
	
	if result:
		pos = result.position
	else:
		var ray_direction = camera.project_ray_normal(mouse_pos)
		pos = from + ray_direction * max_build_distance
	
	if snap_to_edge:
		pos.x = floor(pos.x / grid_size) * grid_size
		pos.y = floor(pos.y / grid_size) * grid_size
		pos.z = floor(pos.z / grid_size) * grid_size
	else:
		pos = pos.snapped(Vector3(grid_size, grid_size, grid_size))
	
	preview.global_position = pos
	
	# Apply rotation to the ENTIRE preview node, not just the mesh
	preview.rotation_degrees.y = current_rotation
	
	can_build = has_enough_resources(current_piece_cost)
	preview.set_valid(can_build)

func try_place_build():
	if not can_build:
		print("❌ Not enough resources!")
		return
	
	var new_build = current_build_scene.instantiate()
	new_build.global_position = preview.global_position
	# Apply the same rotation to the placed piece
	new_build.rotation_degrees.y = current_rotation
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
