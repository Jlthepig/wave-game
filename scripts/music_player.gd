extends Node3D

@export var music_tracks: Array[AudioStream] = []
@export var shuffle_playlist: bool = true
@export var fade_duration: float = 1.0

@onready var audioplayer: AudioStreamPlayer = $audioplayer

var playlist: Array[AudioStream] = []
var current_index: int = 0

func _ready() -> void:
	if music_tracks.is_empty():
		push_warning("No music tracks assigned to the music player!")
		return
	
	# Create playlist and shuffle if needed
	playlist = music_tracks.duplicate()
	if shuffle_playlist:
		playlist.shuffle()
	
	# Connect the finished signal
	audioplayer.finished.connect(_on_track_finished)
	
	# Play the first track
	play_track(0)

func play_track(index: int) -> void:
	if index < 0 or index >= playlist.size():
		return
	
	current_index = index
	audioplayer.stream = playlist[current_index]
	audioplayer.play()
	print("Now playing: Track %d" % (current_index + 1))

func _on_track_finished() -> void:
	# Move to next track
	current_index += 1
	
	# If we've reached the end, reshuffle and start over
	if current_index >= playlist.size():
		current_index = 0
		if shuffle_playlist:
			playlist.shuffle()
		print("Playlist completed! Starting over...")
	
	# Play next track smoothly
	play_track(current_index)

# Optional: Manual controls
func next_track() -> void:
	_on_track_finished()

func previous_track() -> void:
	current_index = max(0, current_index - 2)
	_on_track_finished()

func stop_music() -> void:
	audioplayer.stop()

func pause_music() -> void:
	audioplayer.stream_paused = true

func resume_music() -> void:
	audioplayer.stream_paused = false
