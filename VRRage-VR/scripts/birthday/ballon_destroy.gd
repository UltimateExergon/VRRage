extends Destruction

func destroy():
	print(self.get_children())
	if self.find_child("String"):
		self.find_child("String").queue_free()
	
	super()
