extends XROrigin3D

func _on_area_3d_body_entered(body):
	if body.is_in_group("CRAFTABLE"):
		body.change_highlight(Globals.outline_color_near)

func _on_area_3d_body_exited(body):
	if body.is_in_group("CRAFTABLE"):
		body.change_highlight(Globals.outline_color)
