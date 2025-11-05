extends Node3D

@export var max_health := 100
var health := max_health

@onready var mesh : MeshInstance3D = $mesh
@export var cost := {"driftwood": 5,"WornRope" : 5}

# Store original materials
var original_materials := []

func _ready():
	# Store copies of the original materials with their textures
	if mesh and mesh.mesh:
		for i in mesh.mesh.get_surface_count():
			var mat = mesh.get_surface_override_material(i)
			if not mat:
				mat = mesh.mesh.surface_get_material(i)
			if mat:
				# Duplicate the material to preserve textures
				original_materials.append(mat.duplicate())
				mesh.set_surface_override_material(i, original_materials[i])
			else:
				original_materials.append(null)

func apply_damage(amount: int):
	health -= amount
	print(name, " took ", amount, " damage. Remaining: ", health)
	
	update_mesh_color()
	
	if health <= 0:
		destroy_tile()

func update_mesh_color():
	if not mesh:
		print("ERROR: No mesh!")
		return
	
	var health_percent = float(health) / float(max_health)
	var brightness = 0.3 + (0.7 * health_percent)
	var tint_color = Color(brightness, brightness, brightness)
	
	# Update surface 0
	if original_materials.size() > 0 and original_materials[0]:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			# Keep the texture but change the albedo color (tints the texture)
			mat.albedo_color = tint_color
	
	# Update surface 1  
	if original_materials.size() > 1 and original_materials[1]:
		var mat = mesh.get_surface_override_material(1)
		if mat:
			# Keep the texture but change the albedo color (tints the texture)
			mat.albedo_color = tint_color

func destroy_tile():
	print(name, " DESTROYED")
	queue_free()
