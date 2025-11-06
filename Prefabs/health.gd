extends Node

@export var health: float = 100.0
@export var max_health: float = 100.0
@export var player : Node3D 

signal health_changed(new_health: float)
signal died()
 
func _ready():
	health = max_health

func damage(amount: float):
	if amount <= 0:
		return
	
	health -= amount
	health = max(health, 0.0)  # Clamp to 0 minimum
	
	health_changed.emit(health)
	
	if health <= 0:
		die()

func heal(amount: float):
	if amount <= 0:
		return
	
	health += amount
	health = min(health, max_health)  # Clamp to max_health
	
	health_changed.emit(health)

func die():
	died.emit()
	get_tree().quit()

func get_health_percentage() -> float:
	return (health / max_health) * 100.0

func is_alive() -> bool:
	return health > 0
