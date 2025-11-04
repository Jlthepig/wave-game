extends Control
@onready var grid := $Panel/GridContainer

var item_icons = {
	"driftwood": preload("res://assets/ui/DriftwoodIcon.png"),
	"WornRope": preload("res://assets/ui/WornropeIcon.png"),
}

func _ready():
	# Make sure this node is in the inventory_ui group
	add_to_group("inventory_ui")
	visible = false

func update_inventory(player_inventory: Dictionary):
	var slots = grid.get_children()
	# Clear all slots
	for slot in slots:
		slot.clear()

	# Fill slots with inventory items
	var i = 0
	for item_name in player_inventory.keys():
		if i >= slots.size():
			break
		var count = player_inventory[item_name]
		if count > 0:  # Only show items with quantity > 0
			var slot = slots[i]
			var icon_tex = item_icons.get(item_name, null)
			if icon_tex:
				slot.set_item(icon_tex, count)
			i += 1

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		visible = !visible
		
		# Handle mouse and pause
		if visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
		
		# Prevent this input from propagating further
		get_viewport().set_input_as_handled()
