extends Label

var score = 0

func _on_object_destroyed():
	score += 100
	text = "Score: %s" % score
