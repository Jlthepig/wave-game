extends Area3D

@export var resource_type := "driftwood"
@export var amount := 1
@export var move_speed := 1.5
@export var lifetime := 15.0
@export var bob_speed := 2.0  # How fast the bob animation cycles
@export var bob_height := 0.2  # How high the bob moves (in units)
@export var target_point: Vector3

@onready var label: Label3D = $Label3D

var player_in_range := false
var bob_time := 0.0  # Accumulated time for bob animation

func _ready():
	label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta):
	# Move slowly toward the target (like being carried by waves)
	var direction = (target_point - global_position).normalized()
	global_position += direction * move_speed * delta
	
	# Delta-based bob animation (frame-rate independent)
	bob_time += delta * bob_speed
	global_position.y += sin(bob_time) * bob_height * delta
	
	# Lifetime check
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	
	# If player is near, allow interaction
	if player_in_range and Input.is_action_just_pressed("interact"):
		pick_up()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		label.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		label.visible = false

func pick_up():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.add_resource(resource_type, amount)
		player.play_collect_animation()
	queue_free()
