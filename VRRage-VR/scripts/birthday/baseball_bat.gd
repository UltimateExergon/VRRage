extends XRToolsPickable

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	
	super()
	
func _on_body_entered(body):
	var destruction_node = body.get_parent().get_parent()
	var linearSpeed = self.linear_velocity.length()
	var angularSpeed = self.angular_velocity.length()
	
	if body is StaticBody3D and destruction_node is Destruction:
		if destruction_node.destroyable_by.has("baseball_bat"):
			print(body)
			if (linearSpeed > 4) or (angularSpeed > 20):
				destruction_node.destroy()
