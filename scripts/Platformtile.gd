extends Node3D

@export var max_health := 100
var health := max_health

func apply_damage(amount: int):
	health -= amount
	print(name, "took", amount, "damage. Remaining:", health)
	
	if health <= 0:
		destroy_tile()

func destroy_tile():
	print(name, "DESTROYED")
	queue_free()  # removes the tile node from the scene
