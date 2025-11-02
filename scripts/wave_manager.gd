extends Node3D

@export var wave_interval := 20.0
var timer := 0.0
var wave_count := 0

signal wave_started(wave_type)

func _process(delta):
	timer += delta
	if timer >= wave_interval:
		timer = 0
		spawn_wave()

func spawn_wave():
	wave_count += 1
	var wave_type = "small"
	if wave_count % 10 == 0:
		wave_type = "tsunami"
	elif wave_count % 5 == 0:
		wave_type = "normal"
	print("Wave incoming:", wave_type)
	emit_signal("wave_started", wave_type)
