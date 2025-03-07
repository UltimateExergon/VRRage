extends MeshInstance3D

@onready var pinjoint = self.get_parent().find_child("PinJoint3D")
@onready var joint_connecter = self.get_parent().get_child(0)

func _process(delta: float) -> void:
	if mesh is ImmediateMesh:
		mesh.clear_surfaces()
	
	if is_instance_valid(joint_connecter):
		draw(pinjoint.position, joint_connecter.position)

func draw(point_a: Vector3, point_b: Vector3):
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_set_color(Color.WHITE)
	
	mesh.surface_add_vertex(point_a)
	mesh.surface_add_vertex(point_b)
	
	mesh.surface_end()
