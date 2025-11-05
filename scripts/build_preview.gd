extends Node3D

@onready var mesh: MeshInstance3D = $Mesh
var can_place := false

func set_mesh(new_mesh: Mesh):
	mesh.mesh = new_mesh

func set_valid(valid: bool):
	can_place = valid
	if valid:
		mesh.material_override.albedo_color = Color(0, 1, 0, 0.4)
	else:
		mesh.material_override.albedo_color = Color(1, 0, 0, 0.4)
