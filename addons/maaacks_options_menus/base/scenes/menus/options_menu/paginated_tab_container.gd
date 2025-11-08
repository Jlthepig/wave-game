class_name PaginatedTabContainer
extends TabContainer

func _unhandled_input(event : InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_page_down"):
		current_tab = (current_tab+1) % get_tab_count()
	elif event.is_action_pressed("ui_page_up"):
		if current_tab == 0:
			current_tab = get_tab_count()-1
		else:
			current_tab = current_tab-1


func _on_button_pressed() -> void:
	if get_parent().get_parent(): get_parent().queue_free()
	else: get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")
 
