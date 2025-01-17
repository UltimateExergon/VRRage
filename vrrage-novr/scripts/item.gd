extends RigidBody3D

@export var dropID : int : set = set_dropID, get = get_dropID

func _ready():
	self.contact_monitor = true
	self.max_contacts_reported = 160
	self.add_to_group("CRAFTABLE")
	self.body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body.is_in_group("CRAFTABLE"):
		print("Crafting:", self, body)
		get_tree().root.get_children()[0].craft(self, body)
		
func set_dropID(id : int) -> void:
	dropID = id
	
func get_dropID() -> int:
	return dropID
