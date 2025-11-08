extends Node3D

@onready var wave_manager = $WaveManager
@onready var platform_root = $PlatformRoot
@onready var player = get_tree().get_first_node_in_group("player")
@export var wave_scene: PackedScene

# Difficulty scaling caps
@export var max_difficulty_multiplier := 1.3 # Caps at 3x base difficulty
@export var waves_to_max_difficulty := 20   # Reaches max at wave 20

func _ready():
	wave_manager.wave_started.connect(_on_wave_started)

func _on_wave_started(wave_type: String):
	var damage = 5
	var speed = 10.0
	
	# Calculate difficulty with a cap
	var difficulty_scale = calculate_capped_difficulty()
	
	match wave_type:
		"small":
			damage = 20 * difficulty_scale
			speed = 1.0
		"normal":
			damage = 30 * difficulty_scale
			speed = 1.5
		"tsunami":
			damage = 35 * difficulty_scale
			speed = 2.0
	
	spawn_wave(damage, speed, wave_type)

func calculate_capped_difficulty() -> float:
	# Start at 0.5, increase by 0.1 per wave, but cap at max_difficulty_multiplier
	var base_difficulty = 0.5 + (wave_manager.wave_count * 0.1)
	return clamp(base_difficulty, 0.5, max_difficulty_multiplier)
	
	# Alternative: Smooth curve that approaches the cap
	# var progress = float(wave_manager.wave_count) / waves_to_max_difficulty
	# return lerp(0.5, max_difficulty_multiplier, clamp(progress, 0.0, 1.0))

func spawn_wave(damage: int, speed: float, wave_type: String):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return
	
	var wave_instance = wave_scene.instantiate()
	add_child(wave_instance)
	
	# Spawn in random direction around player
	var spawn_distance = 40.0
	var angle = randf() * TAU
	var player_xz = Vector3(player.global_position.x, 0, player.global_position.z)
	var spawn_pos = player_xz + Vector3(cos(angle) * spawn_distance, 0, sin(angle) * spawn_distance)
	wave_instance.global_transform.origin = spawn_pos
	
	# Rotate to face player
	var target_pos = Vector3(player.global_position.x, 0, player.global_position.z)
	wave_instance.look_at(target_pos, Vector3.UP)
	
	# Set wave properties
	wave_instance.damage = damage
	wave_instance.speed = speed
	
	# Set wave size based on type
	match wave_type:
		"small":
			wave_instance.scale = Vector3(2, 1, 4)
		"normal":
			wave_instance.scale = Vector3(4, 1.5, 6)
		"tsunami":
			wave_instance.scale = Vector3(8, 3, 12)

func _on_damage_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var health = body.get_node("Health")
		health.die()
