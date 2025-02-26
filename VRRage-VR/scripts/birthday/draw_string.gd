extends MeshInstance3D

@onready var pinjoint = $"../PinJoint3D"
@onready var ballon = $"../Ballon-rigid"

func _process(delta: float) -> void:
	if mesh is ImmediateMesh:
		mesh.clear_surfaces()
		
	if is_instance_valid(ballon):
		draw(pinjoint.position, ballon.position)

func draw(point_a: Vector3, point_b: Vector3):
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_set_color(Color.BLACK)
	
	mesh.surface_add_vertex(point_a)
	mesh.surface_add_vertex(point_b)
	
	mesh.surface_end()
