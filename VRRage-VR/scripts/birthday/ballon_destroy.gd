extends Destruction

func destroy():
	if self.find_child("String"):
		self.find_child("String").queue_free()
	
	super()
