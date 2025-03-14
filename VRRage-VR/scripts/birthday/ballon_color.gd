extends MeshInstance3D

@export var color : Color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	self.set_surface_override_material(0, material)
