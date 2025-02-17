extends Label3D

func update_score(score : int, multiplier : float):
	self.text = "Score: " + str(score) + "  x" + str(multiplier)
