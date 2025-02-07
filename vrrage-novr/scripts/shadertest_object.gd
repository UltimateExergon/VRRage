extends RigidBody3D

@onready var outline_shader = preload("res://shader/outline.gdshader")

const outline_color : Color = Color8(255, 255, 255, 50)
const outline_color_near : Color = Color8(91, 255, 92, 255)
const outline_color_crafting : Color = Color8(196, 195, 0, 150)
const outline_color_crafting_near : Color = Color8(196, 195, 0, 200)
const outline_color_none : Color = Color8(0, 0, 0, 0)
const outline_width : float = 2.0

func _ready():
	make_meshes_unique()
		
	
	for i in get_meshes():
		var material : Material = get_surface_mat(0, i)
		i.mesh.surface_set_material(0, material.duplicate(true))
		
		var new_mat : ShaderMaterial = ShaderMaterial.new()
		new_mat.set_shader(outline_shader)
		new_mat.set_shader_parameter("outline_color", outline_color)
		new_mat.set_shader_parameter("outline_width", outline_width)
		
		material = get_surface_mat(0, i)
		material.set_next_pass(new_mat)
		
func make_meshes_unique():
	for i in get_children():
		for m in get_meshes():
			var mesh_duplicate = m.mesh.duplicate(true)
			if i is MeshInstance3D:
				i.mesh = mesh_duplicate
		
		
func get_surface_mat(ind : int, object : Node):
	return object.mesh.surface_get_material(ind)
	
func change_color(color : Color):
	for i in get_meshes():
		var shaderMat : ShaderMaterial = get_surface_mat(0, i).get_next_pass()
		shaderMat.set_shader_parameter("outline_color", color)

func get_meshes() -> Array:
	var meshes : Array = []
	for i in get_children():
		if i is MeshInstance3D:
			meshes.append(i)
			
	return meshes
