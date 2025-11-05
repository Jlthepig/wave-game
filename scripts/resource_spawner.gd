extends Node3D
@export var target_point: Marker3D
@export var spawn_radius := 40.0
@export var spawn_interval := 2.0
@export var resource_scenes := {
	"driftwood": preload("res://Prefabs/pickups/DriftwoodPickup.tscn"),
	"WornRope": preload("res://Prefabs/pickups/RopePickup.tscn"),
}

# Now each resource has its own independent chance (0.0 to 1.0)
# 0.5 = 50% chance, 0.2 = 20% chance, etc.
@export var spawn_chances := {
	"driftwood": 0.7,  # 50% chance each interval
	"WornRope": 0.6,       # 40% chance each interval
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
			spawn_single_resource(name)

func spawn_single_resource(resource_name: String):
	var scene = resource_scenes[resource_name].instantiate()
	
	var angle = randf() * TAU
	var pos = Vector3(cos(angle), 0, sin(angle)) * (spawn_radius * randf_range(0.7, 1.0))
	scene.global_position = target_point.global_position + pos
	get_parent().add_child(scene)
