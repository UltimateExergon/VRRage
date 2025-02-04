extends XRToolsPickable

@export_category("Item")
@export var dropID : String : set = set_dropID, get = get_dropID

var collision_reported : bool = false

@onready var main_node = get_tree().root.get_children()[2]

func _ready():
	self.contact_monitor = true
	self.max_contacts_reported = 160
	self.add_to_group("CRAFTABLE")
	self.body_entered.connect(_on_body_entered)
	
	# Get all grab points
	for child in get_children():
		var grab_point := child as XRToolsGrabPoint
		if grab_point:
			_grab_points.push_back(grab_point)
			
	add_outline_shader()
			
func add_outline_shader():
	var outline_shader = Globals.outline_shader
	for i in get_children():
		if i is MeshInstance3D:
			var mat : Material = i.mesh.surface_get_material(0)
			mat.set_next_pass(outline_shader)
			var next_mat : Material = mat.get_next_pass()
			next_mat.set_shader_param("outline_color", Globals.outline_color)
			next_mat.set_shader_param("outline_width", Globals.outline_width)
	
func _on_body_entered(body):
	if body.is_in_group("CRAFTABLE") and self.got_picked_up == true and collision_reported == false:
		collision_reported = true
		main_node.craft(self, body)
		
func set_dropID(id : String) -> void:
	dropID = id
	
func get_dropID() -> String:
	return dropID
	
