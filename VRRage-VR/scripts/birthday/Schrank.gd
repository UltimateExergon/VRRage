extends XRToolsPickable

func _ready() -> void:
	var schranktuer = get_parent().get_parent().find_child("hohe_schranktuer").get_child(0)
	var baseball_bat = get_parent().get_parent().find_child("baseball_bat").get_child(0)

	self.add_collision_exception_with(schranktuer)
	self.add_collision_exception_with(baseball_bat)
	
	super()
