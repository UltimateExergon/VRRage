extends Node3D

@export var start_pos : Vector3 : get = get_startPos

func _ready():
	print("Loaded level: ", self.name)

func get_startPos() -> Vector3:
	return start_pos
