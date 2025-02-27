extends Destruction

func _on_area_3d_body_entered(body):
	if body.is_in_group("KEY_SAFE"):
		print("KEY DETECTED")
		body.get_parent().destroy()
		self.destroy()
