extends Node3D

@onready var wave_manager = $WaveManager
@onready var platform_root = $PlatformRoot
@onready var player = get_tree().get_first_node_in_group("player")  # Get player reference
@export var wave_scene: PackedScene  # assign the Wave.tscn in the editor

func _ready():
	wave_manager.wave_started.connect(_on_wave_started)

func _on_wave_started(wave_type: String):
	var damage = 5
	var speed = 10.0
	var difficulty_scale = 1.0 + (wave_manager.wave_count * 0.1)
	
	match wave_type:
		"small":
			damage = 25 * difficulty_scale
			speed = 1.0
		"normal":
			damage = 40 * difficulty_scale
			speed = 2.0
		"tsunami":
			damage = 40 * difficulty_scale
			speed = 4.0
	
	spawn_wave(damage, speed, wave_type)

func spawn_wave(damage: int, speed: float, wave_type: String):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return  # No player found, can't spawn wave
	
	var wave_instance = wave_scene.instantiate()
	add_child(wave_instance)
	
	# --- Spawn in random direction around player ---
	var spawn_distance = 40.0
	var angle = randf() * TAU
	var player_xz = Vector3(player.global_position.x, 0, player.global_position.z)
	var spawn_pos = player_xz + Vector3(cos(angle) * spawn_distance, 0, sin(angle) * spawn_distance)
	wave_instance.global_transform.origin = spawn_pos
	
	# --- Rotate to face player (using only X and Z) ---
	var target_pos = Vector3(player.global_position.x, 0, player.global_position.z)
	wave_instance.look_at(target_pos, Vector3.UP)
	
	# --- Set wave damage & speed ---
	wave_instance.damage = damage
	wave_instance.speed = speed
	
	# --- Set wave size based on type ---
	match wave_type:
		"small":
			wave_instance.scale = Vector3(2, 1, 4)   # narrow & low
		"normal":
			wave_instance.scale = Vector3(4, 1.5, 6) # medium
		"tsunami":
			wave_instance.scale = Vector3(8, 3, 12)  # huge

func _on_damage_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var health = body.get_node("Health")
		health.die()
