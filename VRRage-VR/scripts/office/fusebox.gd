extends Destruction

func destroy():
	print("FUSEBOX DESTROYED")
	for i in get_tree().root.get_children():
		if i.is_in_group("ColorLight") or i.is_in_group("Level"):
			i.set_alert_color()

	super()
