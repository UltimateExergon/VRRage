extends Node3D

@export var start_pos : Vector3 : get = get_startPos

func _ready():
	print("Loaded level: ", self.name)
	
	for i in get_children():
		if i.is_in_group("room"):
			i.set_collision_mask(0, false)
			i.set_collision_layer(0, true)

func get_startPos() -> Vector3:
	return start_pos
