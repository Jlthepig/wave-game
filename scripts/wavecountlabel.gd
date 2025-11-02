extends Label

@onready var wave_manager: Node3D = $"../../WaveManager"

func _ready() -> void:
	if wave_manager:
		wave_manager.wave_started.connect(_on_wave_started)
		update_wave_text()

func _on_wave_started(wave_type: String) -> void:
	update_wave_text()

func update_wave_text() -> void:
	if wave_manager:
		text = "Wave: " + str(wave_manager.wave_count)
