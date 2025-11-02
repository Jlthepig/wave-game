extends Area3D

@export var speed := 10.0
@export var damage := 900
@export var lifetime := 10.0

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta):
	translate(Vector3(0, 0, -speed * delta))
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	var current = body
	while current and not current.has_method("apply_damage"):
		current = current.get_parent()

	if current and current.has_method("apply_damage"):
		print("Wave damaged:", current.name)
		current.apply_damage(damage)
