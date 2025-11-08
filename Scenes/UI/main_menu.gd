extends Control

func _on_start_pressed() -> void:
	print("UB VA")
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_options_pressed() -> void:
	print("O")
	get_tree().change_scene_to_file("res://Scenes/scenes/menus/options_menu/master_options_menu_with_tabs.tscn")

func _on_quit_pressed() -> void:
	print("I Bdgnbf ")
	get_tree().quit()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
