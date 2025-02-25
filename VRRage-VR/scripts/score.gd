extends Label3D

@export var show_multiplier : bool = false ##Shows the score multiplier, leave at false if level doesnt use mechanic

func update_score(score : int, multiplier : float):
	self.text = "Score: " + str(score)
	
	if show_multiplier == true:
		self.text += "\n  x" + str(multiplier)
