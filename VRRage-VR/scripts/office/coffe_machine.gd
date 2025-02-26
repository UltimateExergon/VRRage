extends "res://scripts/item.gd"

@export var score_multiplier : float = 2.0
@export var multiplier_time : float = 120.0

func _on_area_3d_body_entered(body):
	print(body)
	if body.is_in_group("MUG"):
		print("MUG DETECTED")
		main_node.set_timed_multiplier(score_multiplier, multiplier_time)
		body.queue_free()
