extends Label3D

@export var show_multiplier : bool = false ##Shows the score multiplier, leave at false if level doesnt use mechanic

func update_score(score : int, multiplier : float, multiplier_timer : float = 0):
	self.text = "Score: " + str(score)
	if show_multiplier == true:
		var time_left: String
		if multiplier_timer == 0:
			time_left = ""
		else:
			time_left = " " + str(round(multiplier_timer)) + "s"
			
		self.text += "\n  x" + str(multiplier) + time_left
