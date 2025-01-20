extends XRToolsPickable

@export_category("Item")
@export var dropID : int : set = set_dropID, get = get_dropID

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
	
func _on_body_entered(body):
	if body.is_in_group("CRAFTABLE") and self.got_picked_up == true:
		print("Crafting:", self, body)
		get_tree().root.get_children()[2].craft(self, body)
		
func set_dropID(id : int) -> void:
	dropID = id
	
func get_dropID() -> int:
	return dropID
	
