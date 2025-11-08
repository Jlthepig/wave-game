extends Node3D

@export var target_point: Marker3D
@export var spawn_radius := 40.0
@export var spawn_interval := 2.0

@export var resource_scenes := {
	"driftwood": preload("res://Prefabs/pickups/DriftwoodPickup.tscn"),
	"WornRope": preload("res://Prefabs/pickups/RopePickup.tscn"),
}

# Chance for each resource to spawn (0.0 to 1.0)
@export var spawn_chances := {
	"driftwood": 0.7,
	"WornRope": 0.6,
}

# Quantity range for each resource type [min, max]
@export var spawn_quantities := {
	"driftwood": Vector2i(1, 3),  # Spawns 1-3 driftwood pieces
	"WornRope": Vector2i(1, 2),   # Spawns 1-2 rope pieces
}

var timer := 0.0

func _process(delta):
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0
		spawn_resources()

func spawn_resources():
	# Check each resource type independently
	for name in spawn_chances.keys():
		if randf() <= spawn_chances[name]:
			spawn_resource_batch(name)

func spawn_resource_batch(resource_name: String):
	# Get the quantity range for this resource
	var qty_range = spawn_quantities.get(resource_name, Vector2i(1, 1))
	var quantity = randi_range(qty_range.x, qty_range.y)
	
	# Spawn the specified quantity
	for i in range(quantity):
		spawn_single_resource(resource_name)

func spawn_single_resource(resource_name: String):
	var scene = resource_scenes[resource_name].instantiate()
	
	# Random position within spawn radius
	var angle = randf() * TAU
	var distance = spawn_radius * randf_range(0.7, 1.0)
	var pos = Vector3(cos(angle), 0, sin(angle)) * distance
	
	scene.global_position = target_point.global_position + pos
	get_parent().add_child(scene)
