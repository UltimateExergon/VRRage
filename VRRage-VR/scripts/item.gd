extends XRToolsPickable

var collision_reported : bool = false

@onready var main_node = get_tree().root.get_children()[Globals.main_order]

# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsPickable"

func _ready():
	self.add_to_group("CRAFTABLE")
	self.body_entered.connect(_on_body_entered)
	
	super()
	
func _on_body_entered(body):
	if body.is_in_group("CRAFTABLE") and self.got_picked_up == true and collision_reported == false:
		collision_reported = true
		main_node.craft(self, body)
