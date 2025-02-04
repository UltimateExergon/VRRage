extends XRToolsPickable

@export_category("Item")
@export var dropID : String : set = set_dropID, get = get_dropID

var collision_reported : bool = false

@onready var main_node = get_tree().root.get_children()[Globals.main_order]

func _ready():
	self.contact_monitor = true
	self.max_contacts_reported = 160
	self.add_to_group("CRAFTABLE")
	self.body_entered.connect(_on_body_entered)
	
	get_all_GrabPoints()
	set_Collisions()
	add_outline_shader()
			
func add_outline_shader():
	var outline_shader : Shader = Globals.outline_shader
	for i in get_children():
		if i is MeshInstance3D:
			var mat : Material = i.mesh.surface_get_material(0)
			var new_mat : ShaderMaterial = ShaderMaterial.new()
			new_mat.set_shader(outline_shader)
			new_mat.set_shader_parameter("outline_color", Globals.outline_color)
			new_mat.set_shader_parameter("outline_width", Globals.outline_width)
			mat.set_next_pass(new_mat)
	
func _on_body_entered(body):
	if body.is_in_group("CRAFTABLE") and self.got_picked_up == true and collision_reported == false:
		collision_reported = true
		main_node.craft(self, body)
		
func set_dropID(id : String) -> void:
	dropID = id
	
func get_dropID() -> String:
	return dropID
	
