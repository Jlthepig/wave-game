extends Node3D

@export var target_point: Marker3D
@export var spawn_radius := 40.0
@export var spawn_interval := 3.0

@export var resource_scenes := {
	"driftwood": preload("res://Prefabs/pickups/DriftwoodPickup.tscn"),
	"rope": preload("res://Prefabs/pickups/RopePickup.tscn"),
	
}

@export var spawn_weights := {
	"driftwood": 0.6,
	"rope": 0.47,
	
}

var timer := 0.0

func _process(delta):
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0
		spawn_resource()

func spawn_resource():
	var r = randf()
	var cumulative = 0.0
	for name in spawn_weights.keys():
		cumulative += spawn_weights[name]
		if r <= cumulative:
			var scene = resource_scenes[name].instantiate()
			
			var angle = randf() * TAU
			var pos = Vector3(cos(angle), 0, sin(angle)) * (spawn_radius * randf_range(0.7, 1.0))
			scene.global_position = target_point.global_position + pos
			get_parent().add_child(scene)
			return
